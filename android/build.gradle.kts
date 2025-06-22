// Top-level build file where you can add configuration options common to all sub-projects/modules.
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:7.3.1") // Match your Android Gradle Plugin version
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.7.20") // Match your Kotlin version
        classpath("com.google.gms:google-services:4.3.15") // Required for Firebase
        
        // NOTE: Do not place your application dependencies here
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Your existing build directory customization
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}