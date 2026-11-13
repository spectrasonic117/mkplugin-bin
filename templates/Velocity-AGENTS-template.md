# AGENTS.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A Minecraft **Velocity proxy plugin** (Velocity API), built with Gradle 9.x and targeting Java 25. All version and plugin metadata lives in `gradle.properties` (`version`, `group`, `projectName`, `javaVersion`, `velocityApiVersion`).

## Commands

```bash
./gradlew build  # Compile and package the plugin JAR
./gradlew clean  # Remove build outputs
```

There is no test suite; `./gradlew test` runs nothing. There are no lint or Checkstyle tasks.

**The plugin JAR is written to `out/` (for example, `out/${PROJECT_NAME}-1.0.0.jar`), not `build/libs/`.** `build.gradle` redirects all `Jar` tasks there through `destinationDirectory`. To install it for testing, place the JAR in a Velocity proxy's `plugins/` directory and restart the proxy.

## Architecture

- Single entry point: `src/main/java/com/spectrasonic/${PROJECT_NAME}/Main.java`, annotated with `@Plugin` and registered on Velocity's event system.
- The Velocity annotation processor, declared as `annotationProcessor` in `build.gradle`, generates `velocity-plugin.json` from the `@Plugin` annotation at compile time. Velocity reads this file to discover the plugin. It is not hand-maintained or resource-filtered.
- The `id`, `name`, and `version` in `@Plugin` are set in the Java source and can drift from `gradle.properties`. When bumping the version, update both `gradle.properties` and the `@Plugin` annotation; `processResources` does not synchronize them.
- Velocity dependencies are `compileOnly`. The proxy provides Velocity API, Guice (`@Inject`), and SLF4J at runtime; do not shade them.

## Conventions

- Event handlers use `@Subscribe` on public methods. Startup logic belongs in a `ProxyInitializeEvent` handler; there is no Bukkit-style `onEnable()`.
