plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.kira.app"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.kira.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        ndk {
            abiFilters.add("arm64-v8a")
        }

        externalNativeBuild {
            cmake {
                arguments.add("-DDART_SDK_PATH=${System.getProperty("user.home")}/development/flutter/bin/cache/dart-sdk")
            }
        }
    }

    externalNativeBuild {
        cmake {
            path = file("src/main/cpp/CMakeLists.txt")
            version = "3.22.1"
        }
    }

    sourceSets["main"].jniLibs.srcDirs("src/main/jniLibs")

    packaging {
        jniLibs {
            keepDebugSymbols += setOf("**/libc++_shared.so")
            pickFirsts += setOf("**/libc++_shared.so",
                                "**/libnode.so",
                                "**/libllama_bridge.so")
            useLegacyPackaging = true
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    aaptOptions {
        noCompress(".gguf")
    }

    sourceSets {
        getByName("main") {
            assets.srcDirs("src/main/assets")
        }
    }
    
    splits {
        abi {
            isEnable = true
            reset()
            include("armeabi-v7a", "arm64-v8a", "x86_64")
            isUniversalApk = true
        }
    }

    // Add model files directly to assets without compression
    applicationVariants.all {
        val variant = this
        val variantName = variant.name.capitalize()
        
        tasks.register<Copy>("copyModelAssets$variantName") {
            from("src/main/arm64/assets/models")
            into("${buildDir}/intermediates/assets/${variant.name}/arm64-v8a/models")
            include("*.gguf")
        }
        
        tasks.named("merge${variantName}Assets") {
            dependsOn("copyModelAssets$variantName")
        }
    }
}

dependencies {
    implementation(platform("org.jetbrains.kotlin:kotlin-bom:1.9.24"))
    implementation("org.jetbrains.kotlin:kotlin-stdlib")
}

flutter {
    source = "../.."
}