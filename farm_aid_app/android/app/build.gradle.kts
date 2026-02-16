plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.farm_aid_app"
    compileSdk = flutter.compileSdkVersion
    
    ndkVersion = "27.0.12077973" 

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17" 
    }

    defaultConfig {
        applicationId = "com.example.farm_aid_app"
        minSdk = 26 
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    androidResources {
        noCompress += listOf("tflite", "lite")
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

// ... (keep your existing plugins and android { } block as is)

dependencies {
    // Core LiteRT runtime (The new name for TFLite)
    implementation("com.google.ai.edge.litert:litert:1.4.1")
    
    // ✅ The specific fix for FlexConv2D - Note the new Group ID: 'io.github.google-ai-edge'
    implementation("io.github.google-ai-edge:litert-select-tf-ops:0.1.0")
}

configurations.all {
    // This stops the "Duplicate Class" error by removing the old TFLite versions
    exclude(group = "org.tensorflow", module = "tensorflow-lite")
    exclude(group = "org.tensorflow", module = "tensorflow-lite-api")
    
    resolutionStrategy {
        // Force everything to align with the 1.4.1 runtime
        force("com.google.ai.edge.litert:litert:1.4.1")
    }
}