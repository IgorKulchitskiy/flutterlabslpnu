plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.project"

    // ✅ ОБОВʼЯЗКОВО >= 30
    compileSdk = 34

    defaultConfig {
        applicationId = "com.example.project"

        // ✅ ПІДТРИМКА ANDROID 10
        minSdk = flutter.minSdkVersion
        targetSdk = 34

        versionCode = 1
        versionName = "1.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
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
