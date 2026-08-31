plugins {
    // Google Services plugin — applied to :app subproject only (apply false here)
    id("com.google.gms.google-services") version "4.3.15" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Kotlin 2.x removed support for languageVersion < 1.8.
// Some Flutter plugins (e.g. sentry_flutter) still set 1.6 internally.
// configureEach is lazy — runs when each task is created, avoiding
// the "project already evaluated" issue from afterEvaluate.
subprojects {
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions {
            languageVersion.set(
                org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_2_0
            )
            apiVersion.set(
                org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_2_0
            )
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
