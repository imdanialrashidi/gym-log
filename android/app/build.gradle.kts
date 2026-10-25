import javax.xml.parsers.DocumentBuilderFactory
import org.w3c.dom.Element

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.gym_log"
    // Pinned to the Flutter 3.47.7 stable Android defaults. See docs/DEVELOPMENT.md.
    compileSdk = 36

    // Flutter 3.47's Android plugin provisions the NDK for every Android app,
    // including pure Dart apps. Pin the revision the SDK expects.
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // The permanent identity is an owner decision. The release guard below
        // refuses release builds while this remains under com.example.
        applicationId = "com.example.gym_log"
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Release signing is out of scope until the owner supplies the
            // permanent identity and signing plan. The release guards below
            // prevent an accidental placeholder release.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

// ---------------------------------------------------------------------------
// Release guards
//
// NFR-ARCH-001: release builds must not declare INTERNET.
// DAT-007 / NFR-PRV-001: Android backup must be disabled by default.
// Section 23.5: a placeholder applicationId must never be released.
//
// These tasks are wired into assembleRelease/bundleRelease. They also run in
// isolation in the verification lane so the merged release manifest is checked
// without producing a release artifact.
// ---------------------------------------------------------------------------

val placeholderApplicationId = "com.example.gym_log"
val releaseTaskNames = setOf("assembleRelease", "bundleRelease")
val configuredApplicationId: String? = android.defaultConfig.applicationId

tasks.register("verifyReleaseApplicationId") {
    group = "verification"
    description = "Refuses release builds while applicationId is a placeholder."
    doLast {
        if (configuredApplicationId == null ||
            configuredApplicationId.startsWith("com.example.")
        ) {
            throw GradleException(
                "Release build refused: applicationId \"$configuredApplicationId\" " +
                    "is a placeholder ($placeholderApplicationId). The owner must " +
                    "choose the permanent applicationId before a release."
            )
        }
        logger.lifecycle(
            "Release applicationId verified: $configuredApplicationId."
        )
    }
}

tasks.register("verifyReleaseManifest") {
    group = "verification"
    description = "Rejects a release manifest with INTERNET or enabled backup."
    dependsOn("processReleaseMainManifest")
    doLast {
        val manifestFile = tasks.named("processReleaseMainManifest").get()
            .outputs.files.files
            .firstOrNull { it.name == "AndroidManifest.xml" }
            ?: throw GradleException(
                "Release manifest verification failed: merged release manifest not found."
            )

        val document = DocumentBuilderFactory.newInstance()
            .apply { isNamespaceAware = true }
            .newDocumentBuilder()
            .parse(manifestFile)
        val androidNamespace = "http://schemas.android.com/apk/res/android"

        val permissionNames = mutableListOf<String>()
        for (tag in listOf("uses-permission", "uses-permission-sdk-23")) {
            val nodes = document.getElementsByTagName(tag)
            for (index in 0 until nodes.length) {
                val element = nodes.item(index) as? Element ?: continue
                permissionNames += element.getAttributeNS(androidNamespace, "name")
            }
        }
        if ("android.permission.INTERNET" in permissionNames) {
            throw GradleException(
                "Release manifest verification failed: INTERNET permission is present. " +
                    "NFR-ARCH-001 requires no network permission in release builds."
            )
        }
        if ("android.permission.POST_NOTIFICATIONS" in permissionNames) {
            throw GradleException(
                "Release manifest verification failed: POST_NOTIFICATIONS is present. " +
                    "SET-004 requires an in-app reminder without notification permission."
            )
        }
        val forbiddenStoragePermissions = setOf(
            "android.permission.READ_EXTERNAL_STORAGE",
            "android.permission.WRITE_EXTERNAL_STORAGE",
            "android.permission.MANAGE_EXTERNAL_STORAGE",
            "android.permission.READ_MEDIA_IMAGES",
            "android.permission.READ_MEDIA_VIDEO",
            "android.permission.READ_MEDIA_AUDIO",
            "android.permission.READ_MEDIA_VISUAL_USER_SELECTED",
            "android.permission.ACCESS_MEDIA_LOCATION",
        )
        val storagePermissions = permissionNames.filter {
            it in forbiddenStoragePermissions
        }
        if (storagePermissions.isNotEmpty()) {
            throw GradleException(
                "Release manifest verification failed: broad storage permission(s) " +
                    "${storagePermissions.joinToString()} are present. IO-006/PHO-001 " +
                    "require the system document/photo UI without broad storage access."
            )
        }
        if ("android.permission.CAMERA" in permissionNames) {
            throw GradleException(
                "Release manifest verification failed: CAMERA is present. PHO-001 " +
                    "requires the system camera intent, which needs no permission."
            )
        }
        logger.lifecycle(
            "Release permissions: " +
                (permissionNames.ifEmpty { listOf("<none>") }.joinToString())
        )

        val application = document.getElementsByTagName("application").item(0) as? Element
            ?: throw GradleException(
                "Release manifest verification failed: no <application> element."
            )
        val allowBackup = application.getAttributeNS(androidNamespace, "allowBackup")
        val fullBackupContent = application.getAttributeNS(
            androidNamespace,
            "fullBackupContent",
        )
        val dataExtractionRules = application.getAttributeNS(
            androidNamespace,
            "dataExtractionRules",
        )

        if (allowBackup != "false") {
            throw GradleException(
                "Release manifest verification failed: android:allowBackup must be " +
                    "\"false\" (DAT-007). Found \"$allowBackup\"."
            )
        }
        if (fullBackupContent != "false") {
            throw GradleException(
                "Release manifest verification failed: android:fullBackupContent must " +
                    "be \"false\" (DAT-007). Found \"$fullBackupContent\"."
            )
        }
        if (dataExtractionRules.isBlank()) {
            throw GradleException(
                "Release manifest verification failed: android:dataExtractionRules is " +
                    "missing (DAT-007)."
            )
        }

        logger.lifecycle(
            "Release manifest verified: no INTERNET; backup disabled; " +
                "data-extraction rules present."
        )
    }
}

tasks.matching { it.name in releaseTaskNames }.configureEach {
    dependsOn("verifyReleaseApplicationId", "verifyReleaseManifest")
}
