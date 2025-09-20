plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.sathi4life"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.sathi4life"
        minSdk = 23
        targetSdk = 33
        versionCode = 1
        versionName = "1.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    signingConfigs {
        create("release") {
            keyAlias = "yourKeyAlias"
            keyPassword = "yourKeyPassword"
            storeFile = file("path/to/your/keystore.jks")
            storePassword = "yourStorePassword"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
} // <-- This closes the android block

flutter {
    source = "../.."
} // <-- This closes the flutter block
dependencies {
    implementation ("com.google.android.material:material:1.12.0")
}
