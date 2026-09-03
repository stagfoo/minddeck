package com.minddeck.minddeck

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.content.pm.ResolveInfo
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.DisplayMetrics
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors

/**
 * The Android half of the launcher: what can be launched, what it looks like,
 * and actually launching it.
 *
 * Everything about *arranging* those apps — grid geometry, ordering, pinning —
 * is plain Dart, so it can be tested without a device.
 */
class MainActivity : FlutterActivity() {
    private val methodChannelName = "minddeck/launcher"
    private val eventChannelName = "minddeck/packages"

    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    private var packageEvents: EventChannel.EventSink? = null
    private var packageReceiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, methodChannelName)
            .setMethodCallHandler { call, result -> handle(call, result) }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventChannelName)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    packageEvents = events
                    registerPackageReceiver()
                }

                override fun onCancel(arguments: Any?) {
                    unregisterPackageReceiver()
                    packageEvents = null
                }
            })
    }

    /**
     * Pressing home while already home should reset to the top level rather
     * than do nothing, the way every stock launcher behaves.
     */
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (intent.hasCategory(Intent.CATEGORY_HOME)) {
            main.post {
                MethodChannel(
                    flutterEngine!!.dartExecutor.binaryMessenger, methodChannelName
                ).invokeMethod("homePressed", null)
            }
        }
    }

    override fun onDestroy() {
        unregisterPackageReceiver()
        worker.shutdown()
        super.onDestroy()
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "listApps" -> onWorker(result) { listApps() }
            "appIcon" -> {
                val pkg = call.argument<String>("packageName") ?: ""
                val size = call.argument<Int>("size") ?: 128
                onWorker(result) { appIcon(pkg, size) }
            }
            "launch" -> result.success(launch(call.argument<String>("packageName") ?: ""))
            "openAppInfo" -> {
                openAppInfo(call.argument<String>("packageName") ?: "")
                result.success(null)
            }
            "requestUninstall" -> {
                requestUninstall(call.argument<String>("packageName") ?: "")
                result.success(null)
            }
            "openSettings" -> {
                startActivity(Intent(Settings.ACTION_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                result.success(null)
            }
            "openHomeSettings" -> {
                openHomeSettings()
                result.success(null)
            }
            "isDefaultLauncher" -> result.success(isDefaultLauncher())
            "screenMetrics" -> result.success(screenMetrics())
            else -> result.notImplemented()
        }
    }

    private fun onWorker(result: MethodChannel.Result, work: () -> Any?) {
        worker.execute {
            try {
                val value = work()
                main.post { result.success(value) }
            } catch (e: Throwable) {
                main.post { result.error("failed", e.message, null) }
            }
        }
    }

    /**
     * Every launchable activity, which is not the same as every installed
     * package: this is the list a launcher is supposed to show, it excludes
     * services and libraries for free, and it correctly surfaces packages that
     * expose more than one launcher entry.
     */
    private fun listApps(): List<Map<String, Any?>> {
        val pm = packageManager
        val intent = Intent(Intent.ACTION_MAIN, null)
            .addCategory(Intent.CATEGORY_LAUNCHER)

        @Suppress("DEPRECATION")
        val resolved: List<ResolveInfo> = pm.queryIntentActivities(intent, 0)

        return resolved.map { info ->
            val activity = info.activityInfo
            mapOf(
                "packageName" to activity.packageName,
                "activityName" to activity.name,
                "label" to info.loadLabel(pm).toString(),
                "isSystem" to isSystem(activity.packageName)
            )
        }
    }

    private fun isSystem(packageName: String): Boolean = try {
        @Suppress("DEPRECATION")
        val flags = packageManager.getApplicationInfo(packageName, 0).flags
        (flags and android.content.pm.ApplicationInfo.FLAG_SYSTEM) != 0
    } catch (e: PackageManager.NameNotFoundException) {
        false
    }

    private fun launch(packageName: String): Boolean {
        val intent = packageManager.getLaunchIntentForPackage(packageName) ?: return false
        // NEW_TASK because the launcher is not the launched app's parent, and
        // RESET_TASK_IF_NEEDED so re-launching returns to the app's root rather
        // than wherever it was left, matching stock launcher behaviour.
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED)
        return try {
            startActivity(intent)
            true
        } catch (e: SecurityException) {
            false
        }
    }

    private fun openAppInfo(packageName: String) {
        startActivity(
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                .setData(Uri.fromParts("package", packageName, null))
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        )
    }

    @Suppress("DEPRECATION")
    private fun requestUninstall(packageName: String) {
        startActivity(
            Intent(Intent.ACTION_DELETE)
                .setData(Uri.fromParts("package", packageName, null))
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        )
    }

    /**
     * Opens the picker that assigns the default home app. There is no API to
     * set it directly — by design — so this is the whole of "make me the
     * launcher".
     */
    private fun openHomeSettings() {
        val intent = Intent(Settings.ACTION_HOME_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        if (intent.resolveActivity(packageManager) != null) {
            startActivity(intent)
        } else {
            // Some skinned builds drop the dedicated home-settings screen.
            startActivity(Intent(Settings.ACTION_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        }
    }

    private fun isDefaultLauncher(): Boolean {
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
        @Suppress("DEPRECATION")
        val resolved: ResolveInfo? =
            packageManager.resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY)
        return resolved?.activityInfo?.packageName == packageName
    }

    /**
     * The real panel geometry, so the Dart side can lay out against measured
     * numbers rather than assumed ones — this screen is an unusual near-square
     * and nothing about it should be guessed.
     */
    private fun screenMetrics(): Map<String, Any> {
        val metrics: DisplayMetrics = resources.displayMetrics
        return mapOf(
            "widthPx" to metrics.widthPixels,
            "heightPx" to metrics.heightPixels,
            "density" to metrics.density,
            "densityDpi" to metrics.densityDpi
        )
    }

    private fun appIcon(packageName: String, size: Int): ByteArray? {
        val drawable: Drawable = try {
            packageManager.getApplicationIcon(packageName)
        } catch (e: PackageManager.NameNotFoundException) {
            return null
        }
        val bitmap = if (drawable is BitmapDrawable && drawable.bitmap != null) {
            Bitmap.createScaledBitmap(drawable.bitmap, size, size, true)
        } else {
            // Adaptive icons have no single backing bitmap — they have to be
            // rasterised through a Canvas at the size we want.
            val bmp = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
            drawable.setBounds(0, 0, size, size)
            drawable.draw(Canvas(bmp))
            bmp
        }
        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
        return stream.toByteArray()
    }

    /**
     * Installing or removing an app has to redraw the grid immediately — a home
     * screen showing a tile for an app that no longer exists is the most
     * obvious way for a launcher to feel broken.
     */
    private fun registerPackageReceiver() {
        if (packageReceiver != null) return
        val receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                packageEvents?.success(intent?.data?.encodedSchemeSpecificPart ?: "")
            }
        }
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_PACKAGE_ADDED)
            addAction(Intent.ACTION_PACKAGE_REMOVED)
            addAction(Intent.ACTION_PACKAGE_CHANGED)
            addAction(Intent.ACTION_PACKAGE_REPLACED)
            addDataScheme("package")
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            registerReceiver(receiver, filter)
        }
        packageReceiver = receiver
    }

    private fun unregisterPackageReceiver() {
        packageReceiver?.let {
            try {
                unregisterReceiver(it)
            } catch (e: IllegalArgumentException) {
                // Already gone; nothing to undo.
            }
        }
        packageReceiver = null
    }
}
