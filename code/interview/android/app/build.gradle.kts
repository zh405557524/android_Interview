import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
if (!keystorePropertiesFile.exists()) {
    throw GradleException(
        "缺少 android/key.properties。请配置现有 android/app/lxwx.jks 的密码与别名。",
    )
}

val keystoreProperties = Properties().apply {
    load(FileInputStream(keystorePropertiesFile))
}

val lxwxKeystoreFile = file(keystoreProperties["storeFile"] as String)
if (!lxwxKeystoreFile.exists()) {
    throw GradleException(
        "找不到签名文件 ${lxwxKeystoreFile.absolutePath}，请将 lxwx.jks 放在 android/app/ 目录。",
    )
}

val appUpdateChannel = ((project.findProperty("APP_CHANNEL") as? String)?.trim() ?: "office")
    .let { if (it == "office") "office" else "store" }

android {
    namespace = "com.lxwx.narrate"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.lxwx.narrate"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        resValue("string", "app_update_channel", appUpdateChannel)
    }

    signingConfigs {
        create("lxwx") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = lxwxKeystoreFile
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        // debug / profile / release 统一使用 android/app/lxwx.jks
        getByName("debug") {
            signingConfig = signingConfigs.getByName("lxwx")
        }
        getByName("profile") {
            signingConfig = signingConfigs.getByName("lxwx")
        }
        getByName("release") {
            signingConfig = signingConfigs.getByName("lxwx")
            isMinifyEnabled = true
            // 阿里云号码认证 SDK 内部有按字符串查找的 authsdk_* 资源；正式包先只做代码混淆，
            // 不开启资源压缩，避免授权页动画、勾选框等资源被误删后导致一键登录崩溃。
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(fileTree(mapOf("dir" to "libs", "include" to listOf("*.aar"))))
    implementation("androidx.appcompat:appcompat:1.7.1")
}
