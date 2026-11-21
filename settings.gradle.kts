pluginManagement {
    plugins {
        id("com.android.library") version "9.4.1"
    }
    repositories {
        mavenLocal()
        gradlePluginPortal()
        google()
        mavenCentral()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    @Suppress("UnstableApiUsage")
    repositories {
        mavenLocal()
        google()
        mavenCentral()
        val flutterStorageUrl = System.getenv("FLUTTER_STORAGE_BASE_URL") ?: "https://storage.googleapis.com"
        maven("$flutterStorageUrl/download.flutter.io")
    }
}

rootProject.name = "Dhizuku"
include("app", "hidden-api")
apply(from = File(settingsDir, "flutter_ui/.android/include_flutter.groovy"))
