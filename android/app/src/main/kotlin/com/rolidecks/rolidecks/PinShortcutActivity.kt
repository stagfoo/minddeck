package com.rolidecks.rolidecks

import android.app.Activity
import android.content.Context
import android.content.pm.LauncherApps
import android.os.Bundle
import android.widget.Toast

/**
 * Accepts "add to home screen" requests.
 *
 * When an app calls ShortcutManager.requestPinShortcut, Android hands the
 * request to whichever launcher declares CONFIRM_PIN_SHORTCUT. Nothing pins
 * itself: if no launcher answers, the request is silently dropped, which is why
 * the option appeared to do nothing before this existed.
 *
 * It accepts rather than asking. The user already tapped "add to home screen"
 * in the other app, so a second confirmation would only be the launcher
 * doubting them — but a toast says where the shortcut went, since a launcher
 * that files everything under all apps gives no other clue.
 */
class PinShortcutActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val launcherApps =
            getSystemService(Context.LAUNCHER_APPS_SERVICE) as LauncherApps
        val request = try {
            launcherApps.getPinItemRequest(intent)
        } catch (e: Exception) {
            null
        }

        val accepted = request != null &&
            request.requestType == LauncherApps.PinItemRequest.REQUEST_TYPE_SHORTCUT &&
            request.isValid &&
            request.accept() != null

        Toast.makeText(
            this,
            if (accepted) {
                "Added to all apps — file it on a card"
            } else {
                "Could not add that shortcut"
            },
            Toast.LENGTH_SHORT
        ).show()

        finish()
    }
}
