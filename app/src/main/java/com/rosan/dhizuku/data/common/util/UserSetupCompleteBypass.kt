package com.rosan.dhizuku.data.common.util

import android.app.admin.DevicePolicyManager
import android.app.admin.IDevicePolicyManager
import android.annotation.SuppressLint
import android.content.Context
import android.os.Build
import android.os.ParcelFileDescriptor
import moe.shizuku.server.IShizukuService
import rikka.shizuku.Shizuku
import rikka.shizuku.ShizukuBinderWrapper
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

object UserSetupCompleteBypass {
    private const val PREFS = "setup_complete_recovery"
    private const val KEY_USER_ID = "user_id"
    private const val KEY_ORIGINAL = "original_value"
    private const val COMMAND_TIMEOUT_SECONDS = 5L
    private const val MAX_OUTPUT_BYTES = 16 * 1024

    suspend fun <T> runWithTemporaryBypass(
        context: Context,
        userId: Int,
        action: suspend () -> T
    ): T {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return action()
        val original = shizukuExec(
            "settings", "--user", "$userId", "get", "secure", "user_setup_complete"
        )?.output?.trim()
        if (original != "1") return action()

        val prefs = recoveryPreferences(context)
        if (!prefs.edit().putInt(KEY_USER_ID, userId).putString(KEY_ORIGINAL, original).commit()) {
            return action()
        }
        if (!writeSetting(userId, "0")) {
            restorePending(context)
            return action()
        }
        refreshUserSetupComplete(context, userId)
        return try {
            action()
        } finally {
            restorePending(context)
        }
    }

    fun restorePending(context: Context): Boolean {
        val prefs = recoveryPreferences(context)
        val userId = prefs.getInt(KEY_USER_ID, -1)
        val original = prefs.getString(KEY_ORIGINAL, null) ?: return userId == -1
        if (userId < 0 || !writeSetting(userId, original)) return false
        refreshUserSetupComplete(context, userId)
        return prefs.edit().clear().commit()
    }

    private fun recoveryPreferences(context: Context) =
        context.createDeviceProtectedStorageContext()
            .getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun writeSetting(userId: Int, value: String): Boolean =
        shizukuExec(
            "settings", "--user", "$userId", "put", "secure", "user_setup_complete", value
        )?.code == 0

    @SuppressLint("BlockedPrivateApi")
    private fun refreshUserSetupComplete(context: Context, userId: Int) {
        runCatching {
            val manager = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
            val serviceField = manager.javaClass.getDeclaredField("mService").also {
                it.isAccessible = true
            }
            val originalService = serviceField.get(manager) as android.os.IInterface
            val wrapped = IDevicePolicyManager.Stub.asInterface(
                ShizukuBinderWrapper(originalService.asBinder())
            )
            serviceField.set(manager, wrapped)
            try {
                val method = runCatching {
                    manager.javaClass.getDeclaredMethod("forceUpdateUserSetupComplete", Int::class.javaPrimitiveType)
                        .also { it.isAccessible = true }
                        .invoke(manager, userId)
                }
                if (method.isFailure) {
                    manager.javaClass.getDeclaredMethod("forceUpdateUserSetupComplete")
                        .also { it.isAccessible = true }
                        .invoke(manager)
                }
            } finally {
                serviceField.set(manager, originalService)
            }
        }
    }

    private fun shizukuExec(vararg command: String): ShizukuProcessResult? {
        val binder = Shizuku.getBinder()
        if (binder == null || !binder.pingBinder() || Shizuku.isPreV11()) return null
        val service = IShizukuService.Stub.asInterface(binder) ?: return null
        val process = service.newProcess(command, null, null) ?: return null
        val readers = Executors.newFixedThreadPool(3) { task ->
            Thread(task, "setup-state-command").apply { isDaemon = true }
        }
        var completed = false
        try {
            val output = readers.submit<String> { process.inputStream.readAllText() }
            val error = readers.submit<String> { process.errorStream.readAllText() }
            val exitCode = readers.submit<Int> { process.waitFor() }
                .get(COMMAND_TIMEOUT_SECONDS, TimeUnit.SECONDS)
            val result = ShizukuProcessResult(
                exitCode,
                output.get(1, TimeUnit.SECONDS),
                error.get(1, TimeUnit.SECONDS)
            )
            completed = true
            return result
        } catch (_: Throwable) {
            return null
        } finally {
            if (!completed) runCatching { process.destroy() }
            readers.shutdownNow()
        }
    }

    private fun ParcelFileDescriptor?.readAllText(): String {
        if (this == null) return ""
        return ParcelFileDescriptor.AutoCloseInputStream(this).use { input ->
            val output = ByteArrayOutputStream()
            val buffer = ByteArray(1024)
            var total = 0
            while (true) {
                val count = input.read(buffer)
                if (count < 0) break
                total += count
                check(total <= MAX_OUTPUT_BYTES)
                output.write(buffer, 0, count)
            }
            output.toString(Charsets.UTF_8.name())
        }
    }

    private data class ShizukuProcessResult(val code: Int, val output: String, val error: String)
}
