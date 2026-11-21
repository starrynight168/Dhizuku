package com.rosan.dhizuku.ui.activity

import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import androidx.lifecycle.lifecycleScope
import com.rosan.dhizuku.aidl.IDhizukuRequestPermissionListener
import com.rosan.dhizuku.data.common.util.getPackageInfoForUid
import com.rosan.dhizuku.data.common.util.signature
import com.rosan.dhizuku.data.settings.model.room.entity.AppEntity
import com.rosan.dhizuku.data.settings.repo.AppRepo
import com.rosan.dhizuku.data.settings.repo.SettingsRepo
import com.rosan.dhizuku.shared.DhizukuVariables
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject

class RequestPermissionActivity : FlutterFragmentActivity(), KoinComponent {
    companion object {
        const val UID_ERR = -1
        const val AUTO_DENY_SECONDS = 15
    }

    private val appRepo by inject<AppRepo>()
    private val settingsRepo by inject<SettingsRepo>()
    private var uid = UID_ERR
    private var signature = ""
    private var requestPackageName = ""
    private var appLabel = ""
    private var listener: IDhizukuRequestPermissionListener? = null
    private var allowApi = false
    private var responseGiven = false
    private var persisted = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        DhizukuFlutterBridge(this).attach(flutterEngine)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        val validRequest = registerAppEntity(intent)
        super.onCreate(savedInstanceState)
        if (!validRequest) {
            respondPermission(false)
            return
        }
        lifecycleScope.launch {
            val decision = withContext(Dispatchers.IO) {
                if (!settingsRepo.isDhizukuEnabled) false
                else {
                    val entity = appRepo.findByUID(uid)
                    when {
                        settingsRepo.isWhitelistMode && (entity == null || !entity.allowApi) -> false
                        entity?.blocked == true -> false
                        entity?.allowApi == true && entity.signature == signature -> true
                        else -> null
                    }
                }
            }
            if (decision != null) respondPermission(decision)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        responseGiven = false
        persisted = false
        if (!registerAppEntity(intent)) respondPermission(false)
    }

    override fun onPause() {
        super.onPause()
        respondPermission(false)
    }

    fun permissionInitialData(): Map<String, Any> = mapOf(
        "screen" to "permission",
        "request" to mapOf(
            "uid" to uid,
            "packageName" to requestPackageName,
            "label" to appLabel,
            "seconds" to AUTO_DENY_SECONDS
        )
    )

    fun respondPermission(allow: Boolean) {
        if (responseGiven) return
        responseGiven = true
        allowApi = allow
        finish()
    }

    override fun finish() {
        if (!responseGiven) {
            responseGiven = true
            allowApi = false
        }
        super.finish()
        if (persisted) return
        persisted = true
        CoroutineScope(Dispatchers.IO).launch {
            val result = if (allowApi) PackageManager.PERMISSION_GRANTED else PackageManager.PERMISSION_DENIED
            try {
                if (uid != UID_ERR) {
                    val actualSignature = packageManager.getPackageInfoForUid(uid)?.signature
                    if (actualSignature != null) {
                        val entity = appRepo.findByUID(uid)
                        if (entity == null) appRepo.insert(AppEntity(uid = uid, signature = actualSignature, allowApi = allowApi))
                        else appRepo.update(entity.copy(signature = actualSignature, allowApi = allowApi))
                    }
                }
            } finally {
                runCatching { listener?.onRequestPermission(result) }
            }
        }
    }

    private fun registerAppEntity(intent: Intent?): Boolean {
        if (intent == null) return false
        val bundle = listOfNotNull(intent.extras, intent.getBundleExtra("bundle"))
            .firstOrNull { it.containsKey(DhizukuVariables.PARAM_CLIENT_UID) } ?: return false
        val callerUid = bundle.getInt(DhizukuVariables.PARAM_CLIENT_UID, UID_ERR)
        if (callerUid == UID_ERR) return false
        val binder = bundle.getBinder(DhizukuVariables.PARAM_CLIENT_REQUEST_PERMISSION_BINDER) ?: return false
        val requestListener = runCatching {
            IDhizukuRequestPermissionListener.Stub.asInterface(binder)
        }.getOrNull() ?: return false
        val packageInfo = packageManager.getPackageInfoForUid(callerUid) ?: return false
        uid = callerUid
        requestPackageName = packageInfo.packageName
        signature = packageInfo.signature.orEmpty()
        appLabel = packageInfo.applicationInfo?.loadLabel(packageManager)?.toString() ?: requestPackageName
        listener = requestListener
        return true
    }
}
