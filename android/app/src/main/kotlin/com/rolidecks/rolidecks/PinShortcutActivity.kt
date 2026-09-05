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
    private val launcherApps: LauncherApps
        get() = getSystemService(Context.LAUNCHER_APPS_SERVICE) as LauncherApps

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val request = try {
            launcherApps.getPinItemRequest(intent)
        } catch (e: Exception) {
            null
        }

        // accept() returns a boolean, so the previous "!= null" was always
        // true: the toast claimed success even when nothing had been pinned,
        // which is a worse failure than the failure itself.
        val message = when {
            request == null ->
                "That was not a shortcut request"
            request.requestType != LauncherApps.PinItemRequest.REQUEST_TYPE_SHORTCUT ->
                "Only shortcuts can be added, not widgets"
            !request.isValid ->
                "That shortcut request has expired"
            // Only the default launcher may accept a pin request or read the
            // result, so this is the likeliest reason for a shortcut that
            // seemed to be added and then was nowhere.
            !launcherApps.hasShortcutHostPermission() ->
                "Set Rolidecks as your home app first"
            !request.accept() ->
                "Android refused that shortcut"
            else ->
                "Added to all apps — file it on a card"
        }

        Toast.makeText(this, message, Toast.LENGTH_LONG).show()

        finish()
    }
}
