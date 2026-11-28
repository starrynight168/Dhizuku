package com.rosan.dhizuku

import android.app.Application
import android.content.Context

import com.rosan.dhizuku.di.init.appModules
import com.rosan.dhizuku.data.common.util.UserSetupCompleteBypass
import com.rosan.dhizuku.server.DhizukuState

import org.koin.android.ext.koin.androidContext
import org.koin.android.ext.koin.androidLogger
import org.koin.core.component.KoinComponent
import org.koin.core.context.startKoin
import org.koin.core.logger.Level
import org.koin.dsl.module
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

import rikka.sui.Sui

class App : Application(), KoinComponent {
    override fun attachBaseContext(base: Context) {
        super.attachBaseContext(base)
        // MyDhizukuProvider is published before Application.onCreate() runs, so binder
        // calls can arrive while the process is still starting up. Start Koin as early
        // as possible, otherwise any call into MyDhizukuService fails (or crashes) with
        // "KoinApplication has not been started" (#205).
        startKoin {
            androidLogger(Level.ERROR)
            androidContext(this@App)
            modules(appModules)
            modules(module { single { this@App } })
        }
    }

    override fun onCreate() {
        super.onCreate()
        DhizukuState.sync(this)
        Sui.init(packageName)
        CoroutineScope(SupervisorJob() + Dispatchers.IO).launch {
            repeat(3) { attempt ->
                if (UserSetupCompleteBypass.restorePending(this@App)) return@launch
                delay(1000L * (attempt + 1))
            }
        }
    }
}
