plugins {
    id("com.android.application")
    id("com.google.gms.google-services") // Pour Firebase
    id("org.jetbrains.kotlin.android") // Pour Kotlin
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.edubot_new"
    compileSdk = 36 // ✅ mis à jour

    // Forcer la version NDK demandée par Firebase
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.edubot_new"
        minSdk = flutter.minSdkVersion // Conservé pour cloud_firestore
        targetSdk = 36 // ✅ mis à jour
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        debug {
            // ✅ Développement : pas de minification ni suppression de ressources
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("debug")
        }
        release {
            // ✅ Test / build sans optimisation
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("debug")
            proguardFiles(
                getDefaultProguardFile("proguard-android.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.1.2"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-storage")
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("org.jetbrains.kotlin:kotlin-stdlib:1.9.22")
}

flutter {
    source = "../.."
}
