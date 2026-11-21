package com.rosan.dhizuku.di.init

import com.rosan.dhizuku.di.dataModule
import com.rosan.dhizuku.di.reflectModule

val appModules = listOf(
    dataModule,
    reflectModule
)
