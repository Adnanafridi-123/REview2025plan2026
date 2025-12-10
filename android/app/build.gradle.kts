// ✅ CRITICAL: Required imports for signing configuration
import java.util.Properties
import java.io.FileInputStream
import java.io.File

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ✅ Load signing properties
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    println("✅ Loaded key.properties from: ${keystorePropertiesFile.absolutePath}")
    println("   storeFile: ${keystoreProperties["storeFile"]}")
    println("   keyAlias: ${keystoreProperties["keyAlias"]}")
} else {
    println("❌ key.properties not found at: ${keystorePropertiesFile.absolutePath}")
}

android {
    namespace = "com.reflectplan.plan"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // Skip lint for faster builds and avoid memory issues
    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }

    compileOptions {
        // Enable core library desugaring for flutter_local_notifications
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.reflectplan.plan"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // ✅ Signing configuration for release builds
    signingConfigs {
        create("release") {
            val storeFilePath = keystoreProperties["storeFile"] as String?
            keyAlias = keystoreProperties["keyAlias"] as String? ?: ""
            keyPassword = keystoreProperties["keyPassword"] as String? ?: ""
            storeFile = storeFilePath?.let { File(it) }
            storePassword = keystoreProperties["storePassword"] as String? ?: ""
            // Enable V1 and V2 signing
            enableV1Signing = true
            enableV2Signing = true
            println("✅ Release signing config: keyAlias=${keyAlias}, storeFile=${storeFile?.absolutePath}")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
