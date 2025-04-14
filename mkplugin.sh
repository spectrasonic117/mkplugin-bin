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

# === Versions Variables ===
#
# Adventure-Text-Minimessage
adventure_content=$(curl -s "https://central.sonatype.com/artifact/net.kyori/adventure-text-minimessage")
MINIMESSAGE_VERSION=$(echo "$adventure_content" | grep -oE 'pkg:maven/net\.kyori/adventure-text-minimessage@([0-9]+\.[0-9]+\.[0-9]+)' | sed 's/.*@//' | head -n 1)

# Lombok
lombok_content=$(curl -s "https://central.sonatype.com/artifact/org.projectlombok/lombok")
LOMBOK_VERSION=$(echo "$lombok_content" | grep -oE 'pkg:maven/org\.projectlombok/lombok@([0-9]+\.[0-9]+\.[0-9]+)' | sed 's/.*@//' | head -n 1)

# Shadow-Gradle-Plugin
shadow_gradle_content=$(curl -s "https://central.sonatype.com/artifact/com.gradleup.shadow/shadow-gradle-plugin")
GRADLE_SHADOW_VERSION=$(echo "$shadow_gradle_content" | grep -oE 'pkg:maven/com.gradleup.shadow/shadow-gradle-plugin@([0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9]+)?)' | sed 's/.*@//' | head -n 1)


PAPERAPI_VERSION="1.21.1"
API_VERSION="1.21"
ACF_VERSION="0.5.1"
# LOMBOK_VERSION="1.18.36"
# MINIMESSAGE_VERSION="4.18.0"
JAVA_VERSION="21"
#GRADLE_SHADOW_VERSION="9.0.0-beta8"
PLUGIN_VERSION="1.0.0"

AUTHOR="spectrasonic"

# === Directories ===

BASE_DIR="src/main"
RESOURCES_DIR="${BASE_DIR}/resources"
JAVA_DIR="${BASE_DIR}/java/com/${AUTHOR}/${PROJECT_NAME}"

if [ -z "$1" ]; then
  read -p "${BMAGENTA}${BLACK} Plugin Project:${RESET} " PROJECT_NAME
elif [ -d "$1" ]; then
  echo "${RED}El proyecto ya existe, ${WHITE}Usa otro nombre!"
  exit 1
elif [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
  echo "${RED}Uso:"
  echo "${GREEN}mkplugin ${BLUE}<project-name>"
  exit 1
else
  PROJECT_NAME="$1"
fi


git clone git@github.com:spectrasonic117/mkplugin.git -q $PWD/$PROJECT_NAME --depth=1
cd $PWD/$PROJECT_NAME

if [ -d .git ]; then
  command rm -rf .git/
fi

command git init -q


printf "plugins {
    // id(\"io.papermc.paperweight.userdev\") version \"2.0.0-beta.14\"
    id \"com.gradleup.shadow\" version \"${GRADLE_SHADOW_VERSION}\"
    id \"java\"
}

group = \"com.${AUTHOR}\"
version = \"${PLUGIN_VERSION}\"

repositories {
    gradlePluginPortal()
    mavenCentral()
    maven {
        name = \"papermc-repo\"
        url = \"https://repo.papermc.io/repository/maven-public/\"
    }
    maven {
        name = \"sonatype\"
        url = \"https://oss.sonatype.org/content/groups/public/\"
    }
    maven {
        name = \"aikar\"
        url = \"https://repo.aikar.co/content/groups/aikar/\"
    }
}

dependencies {
    compileOnly(\"io.papermc.paper:paper-api:${PAPERAPI_VERSION}-R0.1-SNAPSHOT\") // Paper

    // ACF Aikar
    implementation \"co.aikar:acf-paper:${ACF_VERSION}-SNAPSHOT\"

    // Lombok
    compileOnly \"org.projectlombok:lombok:${LOMBOK_VERSION}\"
    annotationProcessor \"org.projectlombok:lombok:${LOMBOK_VERSION}\"
    // testCompileOnly \"org.projectlombok:lombok:${LOMBOK_VERSION}\"
    // testAnnotationProcessor \"org.projectlombok:lombok:${LOMBOK_VERSION}\"

    // Minimessage - Adventure
    implementation \"net.kyori:adventure-text-minimessage:${MINIMESSAGE_VERSION}\"
    implementation \"net.kyori:adventure-api:${MINIMESSAGE_VERSION}\"

    // Paperweight
    // paperweight.paperDevBundle(\"${PAPERAPI_VERSION}-R0.1-SNAPSHOT\")
}

shadowJar {
    relocate \"co.aikar.commands\", \"com.${AUTHOR}.${PROJECT_NAME}.acf\"
    relocate \"co.aikar.locales\", \"com.${AUTHOR}.${PROJECT_NAME}.locales\"
    destinationDirectory = file(\"\${rootDir}/out\")
    archiveFileName = \"\${rootProject.name}-\${version}.jar\" 
}

build.dependsOn shadowJar

def targetJavaVersion = \"${JAVA_VERSION}\"
java {
    def javaVersion = JavaVersion.toVersion(targetJavaVersion)
    sourceCompatibility = javaVersion
    targetCompatibility = javaVersion
    if (JavaVersion.current() < javaVersion) {
        toolchain.languageVersion = JavaLanguageVersion.of(targetJavaVersion)
    }
}

//  tasks.withType(JavaCompile).configureEach {
//      options.encoding = 'UTF-8'
//
//      if (targetJavaVersion >= 10 || JavaVersion.current().isJava10Compatible()) {
//          options.release.set(targetJavaVersion)
//      }
//  }

processResources {
    def props = [version: version]
    inputs.properties props
    filteringCharset = \"UTF-8\"
    filesMatching(\"plugin.yml\") {
        expand props
    }
}" > build.gradle

printf "rootProject.name = '${PROJECT_NAME}'" > settings.gradle

mkdir -p "$PWD/src/main/resources"
mkdir -p "$PWD/src/main/java/com/${AUTHOR}/${PROJECT_NAME}"

printf "name: ${PROJECT_NAME}
version: '\${version}'
main: com.${AUTHOR}.${PROJECT_NAME}.Main
api-version: '${API_VERSION}'
authors: [Spectrasonic]
" > $PWD/src/main/resources/plugin.yml

touch $PWD/src/main/resources/config.yml

printf "package com.${AUTHOR}.${PROJECT_NAME};

import com.${AUTHOR}.Utils.CommandUtils;
import com.${AUTHOR}.Utils.MessageUtils;

import org.bukkit.plugin.java.JavaPlugin;

public final class Main extends JavaPlugin {

    @Override
    public void onEnable() {

        registerCommands();
        registerEvents();
        CommandUtils.setPlugin(this);
        MessageUtils.sendStartupMessage(this);

    }

    @Override
    public void onDisable() {
        MessageUtils.sendShutdownMessage(this);
    }

    public void registerCommands() {
        // Set Commands Here
    }

    public void registerEvents() {
        // Set Events Here
    }
}
" > ${PWD}/src/main/java/com/${AUTHOR}/${PROJECT_NAME}/Main.java

# Git Commands
command git add .
command git commit -m "🌱 - Initial commit"
command git checkout -b dev

echo " "
# Print Project Info
echo "Project: ${MAGENTA}${PROJECT_NAME}${RESET} created successfully.${RESET}"
echo "Compiler: ${CYAN}Gradle${RESET}"
echo "Paper: ${MAGENTA}${PAPERAPI_VERSION}"