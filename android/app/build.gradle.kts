import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val qaInstrumentation = providers.gradleProperty("candyverseInstrumentation").orNull == "true"
val signingProperties = Properties()
val signingPropertiesPath = System.getenv("CANDYVERSE_KEY_PROPERTIES")
val signingPropertiesFile = signingPropertiesPath?.let { file(it).canonicalFile }
if (signingPropertiesFile != null) {
    require(signingPropertiesFile.isFile) { "External signing properties file is missing." }
    require(!signingPropertiesFile.toPath().startsWith(rootProject.projectDir.parentFile.canonicalFile.toPath())) {
        "Signing credentials must be stored outside the repository."
    }
    signingPropertiesFile.inputStream().use { signingProperties.load(it) }
    for (field in listOf("storeFile", "storePassword", "keyAlias", "keyPassword")) {
        require(!signingProperties.getProperty(field).isNullOrBlank()) { "Missing signing property: $field" }
    }
}

gradle.taskGraph.whenReady {
    if (allTasks.any { it.name.contains("release", ignoreCase = true) }) {
        require(!qaInstrumentation) { "QA instrumentation cannot produce a release." }
        require(signingPropertiesFile != null) {
            "Release signing required. Set CANDYVERSE_KEY_PROPERTIES to an external credentials file."
        }
    }
}

android {
    namespace = "com.renvo.candyverse"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    // SoundPool loads bundled PCM directly through AssetFileDescriptor.
    androidResources {
        noCompress += "wav"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // Profile instrumentation is opt-in and never changes the release variant.
    if (qaInstrumentation) {
        testBuildType = "profile"
    }

    defaultConfig {
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        applicationId = if (qaInstrumentation) "com.renvo.candyverse.qa" else "com.renvo.candyverse"
        manifestPlaceholders["candyverseAppLabel"] = if (qaInstrumentation) "Candyverse QA" else "Candyverse: Block & Bloom"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = 36
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (signingPropertiesFile != null) {
            create("upload") {
                val keystoreFile = file(signingProperties.getProperty("storeFile")).canonicalFile
                require(keystoreFile.isFile) { "External upload keystore is missing." }
                require(!keystoreFile.toPath().startsWith(rootProject.projectDir.parentFile.canonicalFile.toPath())) {
                    "Upload keystore must be stored outside the repository."
                }
                storeFile = keystoreFile
                storeType = signingProperties.getProperty("storeType", "PKCS12")
                storePassword = signingProperties.getProperty("storePassword")
                keyAlias = signingProperties.getProperty("keyAlias")
                keyPassword = signingProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("upload")
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

dependencies {
    androidTestImplementation("androidx.test:runner:1.2.0")
    androidTestImplementation("androidx.test:rules:1.2.0")
}
