plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}


android {
    namespace = "com.tonihj77.impeter"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.11718014"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.tonihj77.impeter"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

import java.io.File
import java.util.Properties

val localProperties = Properties().apply {
    file("../local.properties").inputStream().use { load(it) }
}
val flutterSdkPath: String = localProperties.getProperty("flutter.sdk")
val engineVersion: String = File("$flutterSdkPath/bin/cache/engine.stamp").readText().trim()

dependencies {
    debugImplementation("io.flutter:flutter_embedding_debug:1.0.0-$engineVersion")
    profileImplementation("io.flutter:flutter_embedding_profile:1.0.0-$engineVersion")
    releaseImplementation("io.flutter:flutter_embedding_release:1.0.0-$engineVersion")
}
