import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

// Function to get a property from file or environment
fun getSecret(key: String): String? {
    // 1. Check local key.properties
    if (keystorePropertiesFile.exists()) {
        if (keystoreProperties.isEmpty) {
            keystoreProperties.load(FileInputStream(keystorePropertiesFile))
        }
        val value = keystoreProperties[key] as? String
        if (value != null && !value.contains("\${")) {
            return value
        }
    }
    
    // 2. Map camelCase key to SNAKE_CASE for .env/System Env
    val envKey = when(key) {
        "keyAlias" -> "ANDROID_KEY_ALIAS"
        "keyPassword" -> "ANDROID_KEY_PASSWORD"
        "storeFile" -> "ANDROID_STORE_FILE"
        "storePassword" -> "ANDROID_STORE_PASSWORD"
        else -> "ANDROID_" + key.toUpperCase().replace(".", "_")
    }
    
    // 3. Check multiple possible .env locations (Absolute and relative to app/)
    val envPaths = listOf(
        "../../.env", // From root (UniTask/)
        "../.env"     // From android/
    )
    
    for (path in envPaths) {
        val f = File(projectDir, path)
        if (f.exists()) {
            val props = Properties()
            props.load(FileInputStream(f))
            val value = props.getProperty(envKey)
            if (value != null) return value.trim()
        }
    }
    
    // 4. Fallback to System Environment
    return (System.getenv(key) ?: System.getenv(envKey))?.trim()
}

android {
    namespace = "dev.albazeli.unitask"
    compileSdk = flutter.compileSdkVersion
    // ndkVersion = "27.0.12077973" // flutter.ndkVersion is preferred

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "dev.albazeli.unitask"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    signingConfigs {
        create("release") {
            keyAlias = getSecret("keyAlias") ?: ""
            keyPassword = getSecret("keyPassword") ?: ""
            storeFile = getSecret("storeFile")?.let { file(it) }
            storePassword = getSecret("storePassword") ?: ""
        }
    }

    buildTypes {
        release {
            if (signingConfigs.getByName("release").storeFile?.exists() == true) {
                signingConfig = signingConfigs.getByName("release")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}
