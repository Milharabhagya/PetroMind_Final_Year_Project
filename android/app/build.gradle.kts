plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.petromind.petromind"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.petromind.petromind"
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

configurations.all {
    resolutionStrategy {
        force("androidx.core:core:1.13.1")
        force("androidx.core:core-ktx:1.13.1")
        force("androidx.activity:activity:1.9.3")
        force("androidx.activity:activity-ktx:1.9.3")
        force("androidx.browser:browser:1.8.0")
        force("org.jetbrains.kotlin:kotlin-stdlib:2.1.0")
        force("org.jetbrains.kotlin:kotlin-stdlib-jdk7:2.1.0")
        force("org.jetbrains.kotlin:kotlin-stdlib-jdk8:2.1.0")
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
}

flutter {
    source = "../.."
}
