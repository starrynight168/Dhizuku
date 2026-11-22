package com.rosan.dhizuku.ui.activity

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.app.admin.DevicePolicyManager
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.net.Uri
import android.os.Build
import android.os.IBinder
import android.os.Process
import android.provider.Settings
import androidx.activity.ComponentActivity
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.lifecycleScope
import com.rosan.dhizuku.data.account.entity.AccountAuthenticatorEntity
import com.rosan.dhizuku.data.account.entity.AccountEntity
import com.rosan.dhizuku.data.account.repo.UserService
import com.rosan.dhizuku.data.common.util.getPackageInfoForUid
import com.rosan.dhizuku.data.common.util.requireShizukuPermissionGranted
import com.rosan.dhizuku.data.common.util.signature
import com.rosan.dhizuku.command.CommandUserService
import com.rosan.dhizuku.command.ICommandUserService
import com.rosan.dhizuku.data.settings.model.room.entity.AppEntity
import com.rosan.dhizuku.data.settings.repo.AppRepo
import com.rosan.dhizuku.data.settings.repo.SettingsRepo
import com.rosan.dhizuku.server.DhizukuState
import com.rosan.dhizuku.ui.page.settings.activate.ActivateViewModel
import com.rosan.dhizuku.ui.page.settings.activate.ActivateViewState
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeout
import java.io.ByteArrayOutputStream
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject
import org.json.JSONArray
import org.json.JSONObject
import rikka.shizuku.Shizuku

class DhizukuFlutterBridge(private val activity: ComponentActivity) :
    MethodChannel.MethodCallHandler, KoinComponent {
    private var channel: MethodChannel? = null
    private val appRepo by inject<AppRepo>()
    private val settingsRepo by inject<SettingsRepo>()
    private val userService by inject<UserService>()
    private val activateViewModel by lazy {
        ViewModelProvider(activity)[ActivateViewModel::class.java]
    }

    fun attach(engine: FlutterEngine) {
        channel = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL).also {
            it.setMethodCallHandler(this)
        }
    }

    fun notifyPermissionRequest(data: Map<String, Any?>) {
        channel?.invokeMethod("permissionRequestChanged", data["request"])
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getInitialData" -> result.success(
                if (activity is RequestPermissionActivity) activity.permissionInitialData() else {
                    runCatching { DhizukuState.sync(activity) }
                    initialData()
                }
            )
            "respondPermission" -> {
                if (activity is RequestPermissionActivity) {
                    activity.respondPermission(call.argument<Boolean>("allow") == true)
                    result.success(null)
                } else result.error("invalid_state", "No permission request is active", null)
            }
            "acceptAgreement" -> {
                activity.getSharedPreferences("app", Context.MODE_PRIVATE)
                    .edit().putBoolean("agreement", true).apply()
                result.success(null)
            }
            "getSettings" -> result.success(settings())
            "setSetting" -> setSetting(call, result)
            "getCommandFavorites" -> result.success(commandFavorites())
            "saveCommandFavorites" -> saveCommandFavorites(call, result)
            "runShellCommand" -> launch(result) {
                runShellCommand(call.argument<String>("command") ?: error("Missing command"))
            }
            "getAppearance" -> result.success(appearance())
            "setAppearance" -> setAppearance(call, result)
            "getApps" -> launch(result) { apps() }
            "setAppPermission" -> launch(result) { setAppPermission(call) }
            "getUsers" -> launch(result) { users() }
            "removeUser" -> launch(result) { userService.removeUser(call.argument<Int>("userId") ?: error("Missing userId")) }
            "getAccountData" -> launch(result) { accountData(call.argument<Int>("userId") ?: error("Missing userId")) }
            "removeAccount" -> launch(result) { removeAccount(call) }
            "setAuthenticatorEnabled" -> launch(result) { setAuthenticatorEnabled(call) }
            "openSystemAccountSettings" -> {
                val opened = runCatching {
                    activity.startActivity(
                        Intent(Settings.ACTION_SYNC_SETTINGS)
                            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    )
                }.isSuccess
                result.success(opened)
            }
            "getAdmins" -> launch(result) { admins() }
            "activateOwner" -> launch(result) { activateOwner(call) }
            "cancelActivation" -> {
                activateViewModel.cancel()
                result.success(null)
            }
            "deactivateOwner" -> deactivateOwner(result)
            "shutdown" -> {
                result.success(null)
                activity.window.decorView.postDelayed({
                    activity.finish()
                    android.os.Process.killProcess(android.os.Process.myPid())
                }, 250)
            }
            "openUrl" -> {
                val url = call.argument<String>("url") ?: return result.error("invalid_argument", "Missing URL", null)
                activity.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
                result.success(null)
            }
            "requestNotificationPermission" -> {
                (activity as? SettingsActivity)?.requestPostNotificationPermission()
                result.success(null)
            }
            "requestIgnoreBatteryOptimization" -> {
                (activity as? SettingsActivity)?.requestIgnoreBatteryOptimization()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun initialData() = mapOf(
        "agreementAccepted" to activity.getSharedPreferences("app", Context.MODE_PRIVATE)
            .getBoolean("agreement", false),
        "isDeviceOwner" to DhizukuState.state.isDeviceOwner,
        "isProfileOwner" to DhizukuState.state.isProfileOwner,
        "isOwner" to DhizukuState.state.isOwner,
        "settings" to settings()
    )

    private fun settings() = mapOf(
        "dhizukuEnabled" to settingsRepo.isDhizukuEnabled,
        "whitelistMode" to settingsRepo.isWhitelistMode,
        "donateButtonHidden" to settingsRepo.isDonateButtonHidden
    )

    private fun commandFavorites(): List<Map<String, String>> {
        val stored = activity.getSharedPreferences("command_console", Context.MODE_PRIVATE)
            .getString("favorites", "[]")
        val array = JSONArray(stored)
        return (0 until array.length()).mapNotNull { index ->
            val item = array.optJSONObject(index) ?: return@mapNotNull null
            val id = item.optString("id").takeIf(String::isNotBlank) ?: return@mapNotNull null
            val name = item.optString("name").takeIf(String::isNotBlank) ?: return@mapNotNull null
            val command = item.optString("command").takeIf(String::isNotBlank) ?: return@mapNotNull null
            mapOf("id" to id, "name" to name, "command" to command)
        }
    }

    private fun saveCommandFavorites(call: MethodCall, result: MethodChannel.Result) {
        val favorites = call.argument<List<*>>("favorites").orEmpty()
        val array = JSONArray()
        favorites.take(100).forEach { value ->
            val item = value as? Map<*, *> ?: return@forEach
            val id = item["id"] as? String ?: return@forEach
            val name = item["name"] as? String ?: return@forEach
            val command = item["command"] as? String ?: return@forEach
            if (id.isBlank() || name.isBlank() || command.isBlank()) return@forEach
            array.put(JSONObject().put("id", id).put("name", name).put("command", command))
        }
        activity.getSharedPreferences("command_console", Context.MODE_PRIVATE)
            .edit().putString("favorites", array.toString()).apply()
        result.success(null)
    }

    private suspend fun runShellCommand(command: String): Map<String, Any> =
        requireShizukuPermissionGranted {
            val input = command.trim()
            val adbShell = Regex("^adb(?:\\s+-s\\s+\\S+)?\\s+shell(?:\\s+|$)", RegexOption.IGNORE_CASE)
            val normalized = adbShell.replaceFirst(input, "").trim()
            require(normalized.isNotBlank()) { "Enter a shell command" }
            require(!Regex("^adb(?:\\s|$)", RegexOption.IGNORE_CASE).containsMatchIn(input) || normalized != input) {
                "Only adb shell commands are supported; enter adb shell <command>"
            }
            withContext(Dispatchers.IO) {
                val args = Shizuku.UserServiceArgs(
                    ComponentName(activity.packageName, CommandUserService::class.java.name)
                )
                    .tag("dhizuku-command-console")
                    .version(1)
                    .daemon(false)
                    .processNameSuffix("command")
                val (service, connection) = suspendCancellableCoroutine<Pair<ICommandUserService, ServiceConnection>> { continuation ->
                    val callback = object : ServiceConnection {
                        override fun onServiceConnected(name: ComponentName, binder: IBinder) {
                            if (continuation.isActive) {
                                continuation.resumeWith(
                                    Result.success(ICommandUserService.Stub.asInterface(binder) to this)
                                )
                            }
                        }

                        override fun onServiceDisconnected(name: ComponentName) {
                            if (continuation.isActive) {
                                continuation.resumeWith(
                                    Result.failure(IllegalStateException("Shizuku command service disconnected"))
                                )
                            }
                        }
                    }
                    try {
                        Shizuku.bindUserService(args, callback)
                        continuation.invokeOnCancellation {
                            runCatching { Shizuku.unbindUserService(args, callback, true) }
                        }
                    } catch (error: Throwable) {
                        continuation.resumeWith(Result.failure(error))
                    }
                }
                try {
                    val output = JSONObject(service.execute(normalized))
                    mapOf(
                        "stdout" to output.optString("stdout"),
                        "stderr" to output.optString("stderr"),
                        "exitCode" to output.optInt("exitCode", -1)
                    )
                } finally {
                    runCatching { Shizuku.unbindUserService(args, connection, true) }
                }
            }
        }

    private fun appearance(): Map<String, Any?> {
        val preferences = activity.getSharedPreferences("appearance", Context.MODE_PRIVATE)
        return mapOf(
            "themeMode" to preferences.getString("themeMode", "system"),
            "useSystemColor" to preferences.getBoolean("useSystemColor", true),
            "seedColor" to (preferences.getInt("seedColor", 0xff007aff.toInt()).toLong() and 0xffffffffL),
            "systemSeedColor" to systemSeedColor(),
            "colorStyle" to preferences.getString("colorStyle", "vivid")
        )
    }

    private fun setAppearance(call: MethodCall, result: MethodChannel.Result) {
        val themeMode = call.argument<String>("themeMode")
        val colorStyle = call.argument<String>("colorStyle")
        if (themeMode == null || themeMode !in setOf("system", "light", "dark") ||
            colorStyle == null || colorStyle !in setOf("vivid", "tinted", "soft", "monochrome")
        ) {
            result.error("invalid_argument", "Invalid appearance settings", null)
            return
        }
        val seedColor = call.argument<Number>("seedColor")?.toLong()
            ?: return result.error("invalid_argument", "Missing seed color", null)
        val useSystemColor = call.argument<Boolean>("useSystemColor")
            ?: return result.error("invalid_argument", "Missing system color option", null)
        activity.getSharedPreferences("appearance", Context.MODE_PRIVATE).edit()
            .putString("themeMode", themeMode)
            .putBoolean("useSystemColor", useSystemColor)
            .putInt("seedColor", seedColor.toInt())
            .putString("colorStyle", colorStyle)
            .apply()
        result.success(appearance())
    }

    private fun systemSeedColor(): Long? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return null
        val resource = activity.resources.getIdentifier(
            "system_accent1_500",
            "color",
            "android"
        )
        if (resource == 0) return null
        return runCatching { activity.getColor(resource).toLong() and 0xffffffffL }.getOrNull()
    }

    private fun setSetting(call: MethodCall, result: MethodChannel.Result) {
        val enabled = call.argument<Boolean>("enabled") ?: return result.error("invalid_argument", "Missing enabled", null)
        when (call.argument<String>("key")) {
            "dhizukuEnabled" -> settingsRepo.isDhizukuEnabled = enabled
            "whitelistMode" -> settingsRepo.isWhitelistMode = enabled
            "donateButtonHidden" -> settingsRepo.isDonateButtonHidden = enabled
            else -> return result.error("invalid_argument", "Unknown setting", null)
        }
        result.success(settings())
    }

    private suspend fun apps(): List<Map<String, Any?>> = withContext(Dispatchers.IO) {
        val entities = appRepo.all().associateBy { it.uid }
        activity.packageManager.getInstalledPackages(PackageManager.GET_META_DATA or PackageManager.GET_PERMISSIONS)
            .mapNotNull { info ->
                val app = info.applicationInfo ?: return@mapNotNull null
                if (info.packageName == activity.packageName) return@mapNotNull null
                val entity = entities[app.uid]
                val requested = info.requestedPermissions?.contains(com.rosan.dhizuku.shared.DhizukuVariables.PERMISSION_API) == true
                if (!requested && entity == null) return@mapNotNull null
                mapOf(
                    "uid" to app.uid,
                    "packageName" to info.packageName,
                    "label" to app.loadLabel(activity.packageManager).toString(),
                    "icon" to iconBytes(app.loadIcon(activity.packageManager)),
                    "enabled" to (entity?.allowApi ?: false),
                    "blocked" to (entity?.blocked ?: false)
                )
            }
            .distinctBy { it["packageName"] }
            .sortedBy { it["label"].toString().lowercase() }
    }

    private suspend fun setAppPermission(call: MethodCall) = withContext(Dispatchers.IO) {
        val uid = call.argument<Int>("uid") ?: error("Missing uid")
        val key = call.argument<String>("key") ?: error("Missing key")
        val value = call.argument<Boolean>("value") ?: error("Missing value")
        val signature = activity.packageManager.getPackageInfoForUid(uid)?.signature ?: error("App is unavailable")
        val entity = appRepo.findByUID(uid)
        when (key) {
            "enabled" -> if (entity == null) appRepo.insert(AppEntity(uid = uid, signature = signature, allowApi = value))
            else appRepo.update(entity.copy(signature = signature, allowApi = value))
            "blocked" -> if (entity == null) appRepo.insert(AppEntity(uid = uid, signature = signature, allowApi = false, blocked = value))
            else appRepo.update(entity.copy(signature = signature, blocked = value, allowApi = if (value) false else entity.allowApi))
            else -> error("Unknown permission setting")
        }
        true
    }

    private suspend fun users() = withContext(Dispatchers.IO) {
        val currentUserId = runCatching {
            Process.myUserHandle().javaClass.getMethod("getIdentifier")
                .invoke(Process.myUserHandle()) as Int
        }.getOrDefault(0)
        userService.getUsers().sortedBy { it.id }.map {
            mapOf(
                "id" to it.id,
                "name" to (it.name ?: "User ${it.id}"),
                "current" to (it.id == currentUserId)
            )
        }
    }

    private suspend fun accountData(userId: Int) = withContext(Dispatchers.IO) {
        val accounts = userService.getAccounts(userId)
        val auths = userService.getAccountAuthenticators(userId)
        val providersByType = auths.groupBy { it.type }
        mapOf(
            "accounts" to accounts.map { account ->
                val provider = providersByType[account.type]?.firstOrNull()
                mapOf(
                    "userId" to account.userId,
                    "type" to account.type,
                    "name" to account.name,
                    "providerLabel" to provider?.label,
                    "icon" to provider?.let { iconBytes(it.icon) }
                )
            },
            "authenticators" to authenticatorRows(userId, auths, accounts)
        )
    }

    private suspend fun authenticatorRows(
        userId: Int,
        auths: List<AccountAuthenticatorEntity>,
        accounts: List<AccountEntity>
    ): List<Map<String, Any?>> {
        val prefs = activity.getSharedPreferences("frozen_packages_user_$userId", Context.MODE_PRIVATE)
        val saved = prefs.getStringSet("frozen_info", emptySet())?.toMutableSet() ?: mutableSetOf()
        val frozenInfo = saved.mapNotNull { value ->
            val parts = value.split("|", limit = 3)
            if (parts.size == 3) parts[0] to (parts[1] to parts[2]) else null
        }.toMap()
        val activePackages = auths.associateBy { it.packageName }
        val rows = mutableListOf<Map<String, Any?>>()

        auths.forEach { auth ->
            val matchingAccounts = accounts.filter { it.type == auth.type }
            val savedInfo = frozenInfo[auth.packageName]
            var frozen = savedInfo != null
            if (frozen) {
                try {
                    if (userService.isPackageEnabled(auth.packageName, userId)) {
                        frozen = false
                        saved.removeAll { it.startsWith("${auth.packageName}|") }
                    }
                } catch (_: Exception) {
                    frozen = false
                    saved.removeAll { it.startsWith("${auth.packageName}|") }
                }
            }
            if (matchingAccounts.isNotEmpty() || frozen) {
                rows.add(authRow(auth.userId, auth.type, auth.packageName, auth.label, frozen, iconBytes(auth.icon)))
            }
        }

        frozenInfo.forEach { (packageName, info) ->
            if (activePackages.containsKey(packageName)) return@forEach
            val enabled = runCatching { userService.isPackageEnabled(packageName, userId) }.getOrElse {
                saved.removeAll { it.startsWith("$packageName|") }
                false
            }
            if (enabled) saved.removeAll { it.startsWith("$packageName|") }
            rows.add(authRow(
                userId,
                info.first,
                packageName,
                info.second,
                frozen = !enabled,
                icon = packageIconBytes(packageName)
            ))
        }

        prefs.edit().putStringSet("frozen_info", saved).apply()
        return rows.sortedBy { it["label"].toString().lowercase() }
    }

    private fun authRow(
        userId: Int,
        type: String,
        packageName: String,
        label: String,
        frozen: Boolean,
        icon: ByteArray?
    ): Map<String, Any?> = mapOf(
        "userId" to userId,
        "type" to type,
        "packageName" to packageName,
        "label" to label,
        "frozen" to frozen,
        "icon" to icon
    )

    private fun packageIconBytes(packageName: String): ByteArray? = runCatching {
        iconBytes(activity.packageManager.getApplicationIcon(packageName))
    }.getOrNull()

    private suspend fun removeAccount(call: MethodCall) = withContext(Dispatchers.IO) {
        userService.removeAccount(
            AccountEntity(
                userId = call.argument<Int>("userId") ?: error("Missing userId"),
                type = call.argument<String>("type") ?: error("Missing type"),
                name = call.argument<String>("name") ?: error("Missing name")
            )
        )
    }

    private suspend fun setAuthenticatorEnabled(call: MethodCall) = withContext(Dispatchers.IO) {
        val userId = call.argument<Int>("userId") ?: error("Missing userId")
        val packageName = call.argument<String>("packageName") ?: error("Missing packageName")
        val enabled = call.argument<Boolean>("enabled") ?: error("Missing enabled")
        val label = call.argument<String>("label").orEmpty()
        val type = call.argument<String>("type").orEmpty()
        val prefs = activity.getSharedPreferences("frozen_packages_user_$userId", Context.MODE_PRIVATE)
        val success = userService.setPackageEnabled(packageName, enabled, userId)
        if (success) {
            val current = prefs.getStringSet("frozen_info", emptySet())?.toMutableSet() ?: mutableSetOf()
            if (!enabled) {
                current.removeAll { it.startsWith("$packageName|") }
                current.add("$packageName|$type|$label")
            }
            prefs.edit().putStringSet("frozen_info", current).apply()
        }
        success
    }

    @Suppress("DEPRECATION")
    private fun deactivateOwner(result: MethodChannel.Result) {
        runCatching {
            val manager = activity.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
            val state = DhizukuState.state
            check(state.isOwner) { "No active owner to remove" }
            if (state.isProfileOwner) manager.clearProfileOwner(DhizukuState.admin)
            if (state.isDeviceOwner) manager.clearDeviceOwnerApp(activity.packageName)
            DhizukuState.sync(activity)
            check(!DhizukuState.state.isOwner) { "Owner removal did not complete" }
        }.onSuccess { result.success(null) }
            .onFailure { result.error("deactivation_failed", it.message ?: it.javaClass.simpleName, null) }
    }

    private suspend fun admins(): List<Map<String, Any?>> {
        activateViewModel.collectData()
        withTimeout(15_000) {
            while (activateViewModel.state.loading) delay(50)
        }
        return activateViewModel.state.data.map { data ->
            val component = data.admin.component
            mapOf(
                "packageName" to component.packageName,
                "className" to component.className,
                "label" to data.admin.loadLabel(activity.packageManager).toString(),
                "enabled" to data.enabled.toString(),
                "icon" to iconBytes(data.admin.loadIcon(activity.packageManager))
            )
        }
    }

    private suspend fun activateOwner(call: MethodCall) {
        val packageName = call.argument<String>("packageName") ?: error("Missing packageName")
        val className = call.argument<String>("className") ?: error("Missing className")
        val ownerType = call.argument<String>("ownerType") ?: "device"
        val mode = when (call.argument<String>("mode")) {
            "shizuku" -> ActivateViewModel.Mode.Shizuku
            else -> ActivateViewModel.Mode.Dhizuku
        }
        val component = ComponentName(packageName, className)
        if (ownerType == "profile") activateViewModel.activateAsProfileOwner(mode, component)
        else activateViewModel.activateAsDeviceOwner(mode, component)
        withTimeout(5 * 60_000L) {
            while (activateViewModel.state.status is ActivateViewState.Status.Running) delay(100)
        }
        val status = activateViewModel.state.status
        if (status is ActivateViewState.Status.End) status.error?.let { throw it }
        else return
        if (mode == ActivateViewModel.Mode.Dhizuku) DhizukuState.sync(activity)
    }

    private fun launch(result: MethodChannel.Result, block: suspend () -> Any?) {
        activity.lifecycleScope.launch {
            runCatching { block() }
                .onSuccess { value -> result.success(if (value === Unit) null else value) }
                .onFailure {
                    android.util.Log.e("DhizukuFlutterBridge", "Bridge operation failed", it)
                    result.error(
                        "dhizuku_error",
                        "${it.javaClass.simpleName}: ${it.message ?: "Unknown error"}",
                        null
                    )
                }
        }
    }

    companion object {
        const val CHANNEL = "com.rosan.dhizuku/bridge"
    }
}

internal fun iconBytes(drawable: android.graphics.drawable.Drawable): ByteArray? = runCatching {
    val bitmap = Bitmap.createBitmap(96, 96, Bitmap.Config.ARGB_8888)
    try {
        drawable.setBounds(0, 0, bitmap.width, bitmap.height)
        drawable.draw(Canvas(bitmap))
        ByteArrayOutputStream().use { output ->
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, output)
            output.toByteArray()
        }
    } finally {
        bitmap.recycle()
    }
}.getOrNull()
