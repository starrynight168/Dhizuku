package com.rosan.dhizuku.server

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.content.pm.PermissionInfo
import android.os.Build
import android.util.Log
import com.rosan.dhizuku.BuildConfig

data object DhizukuState {
    data class State(val isDeviceOwner: Boolean = false, val isProfileOwner: Boolean = false) {
        val isOwner = isDeviceOwner || isProfileOwner
    }

    @Volatile
    var state = State()
        private set

    val admin = ComponentName(BuildConfig.APPLICATION_ID, DhizukuDAReceiver::class.java.name)

    fun sync(context: Context) {
        val dpm =
            context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        state = State(
            isDeviceOwner = dpm.isDeviceOwnerApp(admin.packageName),
            isProfileOwner = dpm.isProfileOwnerApp(admin.packageName)
        )
        onReceive(context, dpm, admin)
    }

    private fun onReceive(context: Context, dpm: DevicePolicyManager, admin: ComponentName) {
        if (state.isOwner) onEnabled(context, dpm, admin)
        else onDisabled(context, dpm, admin)

        autoDaemonService(context)
    }

    private fun onEnabled(context: Context, dpm: DevicePolicyManager, admin: ComponentName) {
        grantPermissions(context, dpm, admin)
    }

    private fun onDisabled(context: Context, dpm: DevicePolicyManager, admin: ComponentName) {
    }

    private fun grantPermissions(context: Context, dpm: DevicePolicyManager, admin: ComponentName) {
        val permissions = getAllRequestedPermissions(context, admin).filter {
            it ?: return@filter false
            val permission = getPermissionInfo(context, it) ?: return@filter false
            return@filter if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                permission.protection == PermissionInfo.PROTECTION_DANGEROUS
            } else {
                @Suppress("DEPRECATION")
                (permission.protectionLevel and PermissionInfo.PROTECTION_MASK_BASE) == PermissionInfo.PROTECTION_DANGEROUS
            }
        }

        permissions.forEach {
            dpm.setPermissionGrantState(
                admin,
                admin.packageName,
                it,
                DevicePolicyManager.PERMISSION_GRANT_STATE_GRANTED
            )
        }
    }

    private fun getAllRequestedPermissions(context: Context, admin: ComponentName) = try {
        val packageInfo: PackageInfo =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                context.packageManager.getPackageInfo(
                    admin.packageName,
                    PackageManager.PackageInfoFlags.of(PackageManager.GET_PERMISSIONS.toLong())
                )
            } else {
                @Suppress("DEPRECATION")
                context.packageManager.getPackageInfo(
                    admin.packageName,
                    PackageManager.GET_PERMISSIONS
                )
            }
        packageInfo.requestedPermissions ?: emptyArray()
    } catch (_: Exception) {
        emptyArray()
    }

    private fun getPermissionInfo(context: Context, permission: String) = try {
        context.packageManager.getPermissionInfo(permission, 0)
    } catch (e: Exception) {
        null
    }

    private fun autoDaemonService(context: Context) {
        val intent = Intent(context, DaemonService::class.java)
        if (!state.isOwner) {
            context.stopService(intent)
            return
        }
        try {
            context.startForegroundService(intent)
        } catch (error: IllegalStateException) {
            Log.w("DhizukuState", "Unable to start the daemon in the current app state", error)
        } catch (error: SecurityException) {
            Log.w("DhizukuState", "Unable to start the daemon with the current permissions", error)
        }
    }
}
