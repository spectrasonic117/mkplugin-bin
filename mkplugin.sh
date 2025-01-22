#!/usr/bin/env sh

# === Colors ===
BLACK="$(tput setaf 0)"
RED="$(tput setaf 1)"
GREEN="$(tput setaf 2)"
YELLOW="$(tput setaf 3)"
BLUE="$(tput setaf 4)"
MAGENTA="$(tput setaf 5)"
CYAN="$(tput setaf 6)"
WHITE="$(tput setaf 7)"
RESET="$(tput sgr 0)"
BOLD="$(tput bold)"
UNDERLINE="$(tput smul)"
ITALIC="$(tput sitm)"
INVERT="$(tput smso)"

BBLACK="$(tput setab 0)"
BRED="$(tput setab 1)"
BGREEN="$(tput setab 2)"
BYELLOW="$(tput setab 3)"
BBLUE="$(tput setab 4)"
BMAGENTA="$(tput setab 5)"
BCYAN="$(tput setab 6)"
BWHITE="$(tput setab 7)"
BRESET="$(tput sgr 0)"

PAPERAPI_VERSION="1.21"
ACF_VERSION="0.5.1"
LOMBOK_VERSION="1.18.36"
MINIMESSAGE_VERSION="4.18.0"
JAVA_VERSION="21"
GRADLE_SHADOW_VERSION="9.0.0-beta4"

if [ -z "$1" ]; then
  read -p "${BMAGENTA}${BLACK} Plugin Project:${RESET} " PROJECT_NAME
elif [ -d "$1" ]; then
  echo "${RED}El proyecto ya existe, ${WHITE}Usa otro nombre!"
  exit 1
# elif [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
#   echo "${RED}Uso:"
#   echo "${GREEN}mkastro ${BLUE}<project-name> <tailwind|unocss> <preact|react|svelte|vue>${RESET}"
#   exit 1
else
  PROJECT_NAME="$1"
fi


git clone git@github.com:spectrasonic117/mkplugin.git -q $PWD/$PROJECT_NAME
cd $PWD/$PROJECT_NAME

printf '{
  plugins {
    id 'com.gradleup.shadow' version '${GRADLE_SHADOW_VERSION}4'
    id 'java'
}

group = 'com.spectrasonic'
version = '1.0.0'

repositories {
    mavenCentral()
    maven {
        name = "papermc-repo"
        url = "https://repo.papermc.io/repository/maven-public/"
    }
    maven {
        name = "sonatype"
        url = "https://oss.sonatype.org/content/groups/public/"
    }
    maven {
        name = "aikar"
        url = "https://repo.aikar.co/content/groups/aikar/"
    }
}

dependencies {
    compileOnly('io.papermc.paper:paper-api:${PAPERAPI_VERSION}-R0.1-SNAPSHOT') // Paper

    // ACF Aikar
    implementation 'co.aikar:acf-paper:${ACF_VERSION}-SNAPSHOT'

    // Lombok
    compileOnly 'org.projectlombok:lombok:1.18.36'

    // Minimessage - Adventure
    implementation 'net.kyori:adventure-text-minimessage:${MINIMESSAGE_VERSION}'
    implementation 'net.kyori:adventure-api:${MINIMESSAGE_VERSION}'
    // implementation 'net.kyori:adventure-text-serializer-legacy:${MINIMESSAGE_VERSION}' // Legacy

}

shadowJar {
    relocate 'co.aikar.commands', 'com.spectrasonic.${PROJECT_NAME}.acf'
    relocate 'co.aikar.locales', 'com.spectrasonic.${PROJECT_NAME}.locales'
}

build.dependsOn shadowJar

def targetJavaVersion = ${JAVA_VERSION}
java {
    def javaVersion = JavaVersion.toVersion(targetJavaVersion)
    sourceCompatibility = javaVersion
    targetCompatibility = javaVersion
    if (JavaVersion.current() < javaVersion) {
        toolchain.languageVersion = JavaLanguageVersion.of(targetJavaVersion)
    }
}

tasks.withType(JavaCompile).configureEach {
    options.encoding = 'UTF-8'

    if (targetJavaVersion >= 10 || JavaVersion.current().isJava10Compatible()) {
        options.release.set(targetJavaVersion)
    }
}

processResources {
    def props = [version: version]
    inputs.properties props
    filteringCharset 'UTF-8'
    filesMatching('plugin.yml') {
        expand props
    }
}

  }
}' > build.gradle


printf '
rootProject.name = '${PROJECT_NAME}'
' > settings.gradle

mkdir -p src/main/resources
mkdir -p src/main/java/com/spectrasonic/${PROJECT_NAME}

printf "
name: ${PROJECT_NAME}
version: '\${version}'
main: com.spectrasonic.test.Main
api-version: '${PAPERAPI_VERSION}'
" > src/main/resources/plugin.yml

printf "
package com.spectrasonic.${PROJECT_NAME};

import org.bukkit.plugin.java.JavaPlugin;

public final class Main extends JavaPlugin {

    @Override
    public void onEnable() {
        // Plugin startup logic

    }

    @Override
    public void onDisable() {
        // Plugin shutdown logic
    }
}
" > ${PWD}/src/main/java/com/spectrasonic/${PROJECT_NAME}/Main.java

echo "Project: ${MAGENTA}${PROJECT_NAME}${RESET} created successfully.${RESET}"
echo "Compiler: ${CYAN}Gradle${RESET}"
echo "Paper: ${MAGENTA}${PAPERAPI_VERSION}"