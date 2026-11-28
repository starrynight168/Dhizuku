package com.rosan.dhizuku.server

import android.app.admin.DeviceAdminReceiver
import android.app.admin.DevicePolicyManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class DaemonReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        context ?: return
        val action = intent?.action ?: return
        if (action !in allowedActions) return
        DhizukuState.sync(context)
    }

    private companion object {
        val allowedActions = setOf(
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_LOCKED_BOOT_COMPLETED,
            DeviceAdminReceiver.ACTION_DEVICE_ADMIN_ENABLED,
            DeviceAdminReceiver.ACTION_DEVICE_ADMIN_DISABLE_REQUESTED,
            DeviceAdminReceiver.ACTION_DEVICE_ADMIN_DISABLED,
            DevicePolicyManager.ACTION_DEVICE_OWNER_CHANGED,
            DevicePolicyManager.ACTION_PROFILE_OWNER_CHANGED,
            DeviceAdminReceiver.ACTION_PROFILE_PROVISIONING_COMPLETE
        )
    }
}
