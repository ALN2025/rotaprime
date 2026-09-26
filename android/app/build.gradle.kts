plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.rotaprime.rota_prime"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.rotaprime.rota_prime"
        minSdk = flutter.minSdkVersion
        // 34 = mais estavel ao instalar APK fora da Play Store em varios celulares.
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        ndk {
            abiFilters.clear()
            abiFilters.addAll(listOf("armeabi-v7a", "arm64-v8a"))
        }
    }

    splits {
        abi {
            isEnable = false
        }
    }

    signingConfigs {
        create("releaseInstall") {
            storeFile = file("${System.getProperty("user.home")}/.android/debug.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
            enableV1Signing = true
            enableV2Signing = true
            enableV3Signing = true
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("releaseInstall")
        }
    }

    packaging {
        jniLibs {
            // true => libs comprimidas no APK (extractNativeLibs via Gradle, nao no Manifest).
            // Celular: ROTA_LEGACY_PACKAGING=1 (~26 MB ARM). Emulador: mesma flag, so muda --target-platform.
            useLegacyPackaging =
                System.getenv("ROTA_LEGACY_PACKAGING") != "0"
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
