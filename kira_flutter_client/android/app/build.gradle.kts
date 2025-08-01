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
}

dependencies {
    implementation(platform("org.jetbrains.kotlin:kotlin-bom:1.9.24"))
    implementation("org.jetbrains.kotlin:kotlin-stdlib")
}

flutter {
    source = "../.."
}