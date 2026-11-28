package com.rosan.dhizuku.server

import android.annotation.SuppressLint
import android.content.ComponentName
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.Parcel
import android.os.Process
import android.util.Log
import android.widget.Toast

import com.rosan.dhizuku.R
import com.rosan.dhizuku.aidl.IDhizukuClient
import com.rosan.dhizuku.data.common.util.getPackageInfoForUid
import com.rosan.dhizuku.data.common.util.signature
import com.rosan.dhizuku.data.settings.repo.AppRepo
import com.rosan.dhizuku.data.settings.repo.SettingsRepo
import com.rosan.dhizuku.server_api.DhizukuService

import java.lang.reflect.Method

import kotlinx.coroutines.runBlocking

import org.koin.core.component.KoinComponent
import org.koin.core.component.inject

@SuppressLint("PrivateApi")
class MyDhizukuService(context: Context, admin: ComponentName?, client: IDhizukuClient?) :
    DhizukuService(context, admin, client), KoinComponent {
    private val context by inject<Context>()
    private val appRepo by inject<AppRepo>()
    private val settingsRepo by inject<SettingsRepo>()

    private enum class OwnershipVerdict {
        ALLOW,
        BLOCK,
        UNVERIFIABLE
    }

    private data class OwnershipTransactionResolver(
        val blockedCodes: Set<Int>,
        val isCoreComplete: Boolean,
        val getTransactionNameMethod: Method?
    )

    private val ownershipResolver: OwnershipTransactionResolver by lazy {
        val stub = runCatching {
            Class.forName("$DEVICE_POLICY_MANAGER_INTERFACE\$Stub")
        }.onFailure {
            Log.w(TAG, "Failed to load IDevicePolicyManager\$Stub for ownership protection", it)
        }.getOrNull()

        val blockedCodes = LinkedHashSet<Int>()
        val resolvedNames = HashSet<String>()
        if (stub != null) {
            for (methodName in OWNERSHIP_METHOD_NAMES) {
                val code = runCatching {
                    stub.getDeclaredField("TRANSACTION_$methodName").apply { isAccessible = true }.getInt(null)
                }.getOrNull()
                if (code != null) {
                    blockedCodes.add(code)
                    resolvedNames.add(methodName)
                }
            }
        }

        val requiredCoreNames = buildSet {
            add("clearDeviceOwner")
            add("clearProfileOwner")
            add("setDeviceOwner")
            add("setProfileOwner")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                add("transferOwnership")
            }
        }
        val isCoreComplete = requiredCoreNames.all { it in resolvedNames }
        if (!isCoreComplete) {
            Log.w(
                TAG,
                "Incomplete IDevicePolicyManager ownership transaction resolution: resolved=$resolvedNames, required=$requiredCoreNames"
            )
        }

        val getTransactionNameMethod = stub?.let {
            runCatching {
                it.getDeclaredMethod("getDefaultTransactionName", Int::class.javaPrimitiveType).apply {
                    isAccessible = true
                }
            }.getOrNull()
        }

        OwnershipTransactionResolver(
            blockedCodes = blockedCodes,
            isCoreComplete = isCoreComplete,
            getTransactionNameMethod = getTransactionNameMethod
        )
    }

    override fun onRemoteTransact(
        binder: IBinder?,
        code: Int,
        data: Parcel?,
        reply: Parcel?,
        flags: Int
    ): Boolean {
        if (!settingsRepo.isAllowOwnershipChanges && binder != null && getCallingUid() != Process.myUid()) {
            val descriptor = runCatching { binder.interfaceDescriptor }.getOrNull()
            if (descriptor == DEVICE_POLICY_MANAGER_INTERFACE) {
                when (classifyOwnershipTransaction(code)) {
                    OwnershipVerdict.ALLOW -> Unit
                    OwnershipVerdict.BLOCK -> {
                        enforceCallingPermission("remote_transact")
                        Handler(Looper.getMainLooper()).post {
                            Toast.makeText(context, R.string.ownership_change_blocked, Toast.LENGTH_LONG).show()
                        }
                        throw SecurityException("Ownership changes are disabled in Dhizuku settings")
                    }
                    OwnershipVerdict.UNVERIFIABLE -> {
                        enforceCallingPermission("remote_transact")
                        Log.w(
                            TAG,
                            "Blocking unverifiable IDevicePolicyManager transaction $code while ownership-change protection is enabled"
                        )
                        throw SecurityException(
                            "Unable to verify IDevicePolicyManager transaction $code while ownership-change protection is enabled"
                        )
                    }
                }
            }
        }
        return super.onRemoteTransact(binder, code, data, reply, flags)
    }

    private fun classifyOwnershipTransaction(code: Int): OwnershipVerdict {
        if (code !in IBinder.FIRST_CALL_TRANSACTION..IBinder.LAST_CALL_TRANSACTION) {
            return OwnershipVerdict.ALLOW
        }
        val resolver = ownershipResolver
        if (code in resolver.blockedCodes) {
            return OwnershipVerdict.BLOCK
        }
        val getTransactionNameMethod = resolver.getTransactionNameMethod
        if (getTransactionNameMethod != null) {
            val transactionName = runCatching {
                getTransactionNameMethod.invoke(null, code) as? String
            }.getOrNull()
            if (transactionName != null) {
                return if (transactionName in OWNERSHIP_METHOD_NAMES) {
                    OwnershipVerdict.BLOCK
                } else {
                    OwnershipVerdict.ALLOW
                }
            }
        }
        return if (resolver.isCoreComplete) {
            OwnershipVerdict.ALLOW
        } else {
            OwnershipVerdict.UNVERIFIABLE
        }
    }

    override fun checkCallingPermission(func: String?, callingUid: Int, callingPid: Int): Boolean {
        if (!settingsRepo.isDhizukuEnabled) {
            return false
        }

        val entity = runBlocking { appRepo.findByUID(callingUid) }
        if (entity == null) {
            return false
        }

        if (!entity.allowApi || entity.blocked) {
            return false
        }

        val signature = context.packageManager.getPackageInfoForUid(callingUid)?.signature
            ?: return false

        if (signature != entity.signature) {
            return false
        }

        return true
    }

    private companion object {
        const val TAG = "MyDhizukuService"
        const val DEVICE_POLICY_MANAGER_INTERFACE = "android.app.admin.IDevicePolicyManager"
        val OWNERSHIP_METHOD_NAMES = setOf(
            "transferOwnership",
            "clearDeviceOwner",
            "clearDeviceOwnerApp",
            "clearProfileOwner",
            "setDeviceOwner",
            "setProfileOwner"
        )
    }
}
