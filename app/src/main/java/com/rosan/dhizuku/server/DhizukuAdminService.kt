package com.rosan.dhizuku.server

import android.app.admin.DeviceAdminService
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import androidx.core.content.ContextCompat
import com.rosan.dhizuku.data.common.util.getPackageInfoForUid
import com.rosan.dhizuku.data.common.util.signature
import com.rosan.dhizuku.data.settings.model.room.entity.AppEntity
import com.rosan.dhizuku.data.settings.repo.AppRepo
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject

class DhizukuAdminService : DeviceAdminService(), KoinComponent {
    private val scope = CoroutineScope(Dispatchers.IO)

    private val repo by inject<AppRepo>()

    private var packageReceiverRegistered = false

    private val packageReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent == null) return
            val uid = intent.getIntExtra(Intent.EXTRA_UID, -1)
            if (uid < 0) return
            scope.launch {
                val entity = repo.findByUID(uid) ?: return@launch
                if (verify(entity)) return@launch
                repo.delete(entity)
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        registerPackageReceiver()
    }

    override fun onDestroy() {
        if (packageReceiverRegistered) unregisterReceiver(packageReceiver)
        scope.cancel()
        super.onDestroy()
    }

    private fun registerPackageReceiver() {
        scope.launch {
            repo.all().filter { !verify(it) }.forEach { repo.delete(it) }
        }

        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_PACKAGE_REMOVED)
            addAction(Intent.ACTION_PACKAGE_FULLY_REMOVED)
            addAction(Intent.ACTION_PACKAGE_CHANGED)
            addDataScheme("package")
        }
        ContextCompat.registerReceiver(
            this,
            packageReceiver,
            filter,
            ContextCompat.RECEIVER_NOT_EXPORTED
        )
        packageReceiverRegistered = true
    }

    private fun verify(entity: AppEntity): Boolean {
        val packageInfo = packageManager.getPackageInfoForUid(entity.uid) ?: return false

        if (!entity.allowApi || entity.blocked) return false
        if (entity.signature != packageInfo.signature) return false

        return true
    }
}
