package com.rosan.dhizuku.data.account.model

import android.accounts.Account
import android.accounts.IAccountManager
import android.accounts.IAccountManagerResponse
import android.content.Context
import android.content.pm.IPackageManager
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.os.IUserManager
import android.os.RemoteException
import com.rosan.dhizuku.data.common.util.dumpText
import com.rosan.dhizuku.data.common.util.getParcelableCompat
import com.rosan.dhizuku.data.common.util.requireShizukuPermissionGranted
import com.rosan.dhizuku.data.common.util.shizukuBinder
import com.rosan.dhizuku.data.account.entity.AccountAuthenticatorEntity
import com.rosan.dhizuku.data.account.entity.AccountEntity
import com.rosan.dhizuku.data.account.entity.UserEntity
import com.rosan.dhizuku.data.account.repo.UserService
import rikka.shizuku.Shizuku
import kotlin.coroutines.resume
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.suspendCancellableCoroutine
import java.io.File
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

private const val MAX_LOG_BYTES = 512 * 1024L
private const val MAX_LOG_ENTRY_CHARS = 8 * 1024

class ShizukuUserService(private val context: Context) : UserService {
    // 本地包管理器：仅传入包名字符串读取资源，不接收远程ApplicationInfo
    private val basePackageManager by lazy { context.packageManager }
    // Shizuku远程Binder服务
    private val userManager by lazy { IUserManager.Stub.asInterface(shizukuBinder(Context.USER_SERVICE)) }
    private val accountManager by lazy { IAccountManager.Stub.asInterface(shizukuBinder(Context.ACCOUNT_SERVICE)) }
    private val packageManager by lazy { IPackageManager.Stub.asInterface(shizukuBinder("package")) }
    private val logLock = Any()

    private fun writeLog(message: String) {
        try {
            context.getExternalFilesDir(null)?.let { dir ->
                val logFile = File(dir, "log.txt")
                val backupFile = File(dir, "log.txt.1")
                val time = SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS", Locale.getDefault()).format(Date())
                val entry = "[$time] ${message.take(MAX_LOG_ENTRY_CHARS)}\n".toByteArray(Charsets.UTF_8)
                synchronized(logLock) {
                    if (logFile.length() + entry.size > MAX_LOG_BYTES) {
                        backupFile.delete()
                        if (logFile.length() <= MAX_LOG_BYTES && !logFile.renameTo(backupFile)) {
                            logFile.delete()
                        } else if (logFile.length() > MAX_LOG_BYTES) {
                            logFile.delete()
                        }
                    }
                    FileOutputStream(logFile, true).use { it.write(entry) }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override suspend fun removeUser(user: UserEntity): Boolean = removeUser(user.id)

    override suspend fun removeUser(userId: Int): Boolean = requireShizukuPermissionGranted(context) {
        userManager.removeUser(userId)
    }

    override suspend fun getUsers(): List<UserEntity> = requireShizukuPermissionGranted(context) {
        val users = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            try {
                userManager.getUsers(false, false, false)
            } catch (_: NoSuchMethodError) {
                userManager.getUsers(false)
            }
        } else {
            userManager.getUsers(false)
        }
        users.map {
            UserEntity(id = it.id, name = it.name)
        }
    }

    override suspend fun getAccountAuthenticators(userId: Int): List<AccountAuthenticatorEntity> =
        requireShizukuPermissionGranted(context) {
            accountManager.getAuthenticatorTypes(userId).mapNotNull { description ->
                try {
                    val packageName = description.packageName
                    // 本地PackageManager通过【包名字符串】读取资源，不传递远程ApplicationInfo
                    val appLabel = basePackageManager.getApplicationLabel(basePackageManager.getApplicationInfo(packageName, 0)).toString()
                    val descLabel = runCatching {
                        basePackageManager.getText(packageName, description.labelId, null)
                            ?.toString()
                            ?.takeIf { it.isNotBlank() && !it.equals("null", true) }
                    }.getOrNull()
                    val label = listOfNotNull(
                        appLabel.takeIf { it.isNotBlank() },
                        descLabel?.takeIf { it != appLabel },
                    ).joinToString(" - ").ifBlank { packageName }
                    val icon = basePackageManager.getApplicationIcon(packageName)

                    AccountAuthenticatorEntity(
                        userId = userId,
                        type = description.type,
                        packageName = description.packageName,
                        label = label,
                        icon = icon
                    )
                } catch (e: RemoteException) {
                    writeLog("getAccountAuthenticators RemoteException for ${description.packageName}: ${e.message}")
                    null
                } catch (e: Exception) {
                    writeLog("getAccountAuthenticators exception for ${description.packageName}: ${e.message}")
                    null
                }
            }
        }

    override suspend fun getAccounts(userId: Int): List<AccountEntity> =
        requireShizukuPermissionGranted(context) { loadAccounts(userId) }

    private suspend fun loadAccounts(userId: Int): List<AccountEntity> {
        val managerAccounts = try {
            getAccountsByManager(userId)
        } catch (_: NoSuchMethodError) {
            null
        } catch (_: Exception) {
            null
        }
        val dumpAccounts = try {
            getAccountsByDump(userId)
        } catch (error: CancellationException) {
            throw error
        } catch (error: Exception) {
            return managerAccounts ?: throw error
        }
        if (managerAccounts.isNullOrEmpty()) return dumpAccounts

        val namedDumpAccounts = dumpAccounts.filter { it.hasKnownName }.toSet()
        val namedManagerAccounts = managerAccounts.filter { it.hasKnownName }.toSet()
        val extraNamesByType = (namedManagerAccounts - namedDumpAccounts)
            .groupingBy { it.type }.eachCount().toMutableMap()
        val remainingHidden = dumpAccounts.filter { account ->
            if (account.hasKnownName) return@filter false
            val extraNames = extraNamesByType[account.type] ?: 0
            if (extraNames == 0) return@filter true
            extraNamesByType[account.type] = extraNames - 1
            false
        }
        return (namedDumpAccounts + namedManagerAccounts).toList() + remainingHidden
    }

    private fun getAccountsByManager(userId: Int): List<AccountEntity> {
        val callingPackage = try {
            basePackageManager.getPackagesForUid(Shizuku.getUid())?.firstOrNull() ?: "android"
        } catch (_: Exception) {
            "android"
        }
        return accountManager.getAccountsAsUser(null, userId, callingPackage).map {
            AccountEntity(
                userId = userId,
                type = it.type,
                name = it.name
            )
        }
    }

    private suspend fun getAccountsByDump(userId: Int): List<AccountEntity> {
        val text = accountManager.asBinder().dumpText()
        val lines = text.lines()

        val userStartRegex = """^\s*User UserInfo\{(\d+)[:\}].*""".toRegex()
        var inUserBlock = false
        val userLines = mutableListOf<String>()

        for (line in lines) {
            val match = userStartRegex.matchEntire(line)
            if (match != null) {
                val currentUserId = match.groupValues[1].toInt()
                if (currentUserId == userId) {
                    inUserBlock = true
                    continue
                } else if (inUserBlock) {
                    break
                }
            }
            if (inUserBlock) {
                if (line.isNotEmpty() && !line.first().isWhitespace()) {
                    break
                }
                userLines.add(line)
            }
        }

        val accountLines = mutableListOf<String>()
        var foundAccountsSection = false
        for (line in userLines) {
            val trimmed = line.trim()
            if (trimmed.startsWith("Accounts:")) {
                foundAccountsSection = true
                continue
            }
            if (foundAccountsSection) {
                if (line.isEmpty()) continue
                val leadingSpaces = line.length - line.trimStart().length
                if (leadingSpaces <= 2) {
                    break
                }
                accountLines.add(line)
            }
        }

        val accountsText = accountLines.joinToString("\n")
        val accountRegex = """Account\s*\{\s*name=(.*?), type=(.*?)[,}]""".toRegex()

        return accountRegex.findAll(accountsText)
            .map {
                val name = it.groupValues[1]
                val type = it.groupValues[2]

                AccountEntity(
                    userId = userId,
                    type = type,
                    name = name
                )
            }
            .toList()
    }

    override suspend fun removeAccount(account: AccountEntity): String = requireShizukuPermissionGranted(context) {
        if (!account.hasKnownName || account !in loadAccounts(account.userId)) {
            return@requireShizukuPermissionGranted "failed"
        }
        val targetAccount = Account(account.name, account.type)
        suspendCancellableCoroutine<String> { continuation ->
            val response = object : IAccountManagerResponse.Stub() {
                override fun onResult(value: Bundle?) {
                    val intent = value?.getParcelableCompat<android.content.Intent>("intent")
                    val status = if (intent != null) {
                        runCatching {
                            intent.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
                            context.startActivity(intent)
                        }.fold(
                            onSuccess = { "confirmation_required" },
                            onFailure = { "failed" },
                        )
                    } else if (value?.getBoolean("booleanResult", false) == true) {
                        "removed"
                    } else {
                        "failed"
                    }
                    if (continuation.isActive) continuation.resume(status)
                }

                override fun onError(errorCode: Int, errorMessage: String?) {
                    if (continuation.isActive) continuation.resume("failed")
                }
            }
            try {
                accountManager.removeAccountAsUser(response, targetAccount, false, account.userId)
            } catch (e: Exception) {
                if (continuation.isActive) continuation.resumeWith(Result.failure(e))
            }
        }
    }

    override suspend fun setPackageEnabled(packageName: String, enabled: Boolean, userId: Int): Boolean = requireShizukuPermissionGranted(context) {
        val newState = if (enabled) 1 else 3
        val callingPackage = when (Shizuku.getUid()) {
            0 -> "android"
            2000 -> "com.android.shell"
            else -> try {
                basePackageManager.getPackagesForUid(Shizuku.getUid())?.firstOrNull() ?: "android"
            } catch (_: Exception) {
                "android"
            }
        }
        writeLog("setPackageEnabled: pkg=$packageName enabled=$enabled state=$newState callingPkg=$callingPackage userId=$userId")
        try {
            packageManager.setApplicationEnabledSetting(packageName, newState, 0, userId, callingPackage)
            writeLog("setApplicationEnabledSetting success for $packageName")
            true
        } catch (e: Exception) {
            writeLog("setApplicationEnabledSetting error: ${e.message}")
            throw e
        }
    }

    override suspend fun isPackageEnabled(packageName: String, userId: Int): Boolean? =
        requireShizukuPermissionGranted(context) {
            getPackageInfoForUser(packageName, userId)?.applicationInfo?.enabled
        }

    private fun getPackageInfoForUser(packageName: String, userId: Int): PackageInfo? {
        val flags = PackageManager.MATCH_DISABLED_COMPONENTS
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            try {
                packageManager.getPackageInfo(packageName, flags.toLong(), userId)
            } catch (_: NoSuchMethodError) {
                packageManager.getPackageInfo(packageName, flags, userId)
            }
        } else {
            packageManager.getPackageInfo(packageName, flags, userId)
        }
    }
}
