plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter plugin harus di bawah Android dan Kotlin
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.basketcounterv8" // WAJIB untuk AGP 8+
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.example.basketcounterv8"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
