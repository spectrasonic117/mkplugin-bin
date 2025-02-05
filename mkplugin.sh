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

PAPERAPI_VERSION="1.21"
ACF_VERSION="0.5.1"
LOMBOK_VERSION="1.18.36"
MINIMESSAGE_VERSION="4.18.0"
JAVA_VERSION="21"
GRADLE_SHADOW_VERSION="9.0.0-beta6"
PLUGIN_VERSION="1.0.0"

# === Directories ===

BASE_DIR="src/main"
RESOURCES_DIR="${BASE_DIR}/resources"
JAVA_DIR="${BASE_DIR}/java/com/spectrasonic/${PROJECT_NAME}/Utils"

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


git clone git@github.com:spectrasonic117/mkplugin.git -q $PWD/$PROJECT_NAME
cd $PWD/$PROJECT_NAME

if [ -d .git ]; then
  command rm -rf .git/
fi

command git init -q
command git add .
command git commit -m "🌱 - Initial commit"

printf "plugins {
    id \"com.gradleup.shadow\" version \"${GRADLE_SHADOW_VERSION}\"
    id \"java\"
}

group = \"com.spectrasonic\"
version = \"${PLUGIN_VERSION}\"

repositories {
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
    compileOnly \"org.projectlombok:lombok:1.18.36\"

    // Minimessage - Adventure
    implementation \"net.kyori:adventure-text-minimessage:${MINIMESSAGE_VERSION}\"
    implementation \"net.kyori:adventure-api:${MINIMESSAGE_VERSION}\"
    // implementation \"net.kyori:adventure-text-serializer-legacy:${MINIMESSAGE_VERSION}\" // Legacy

}

shadowJar {
    relocate \"co.aikar.commands\", \"com.spectrasonic.${PROJECT_NAME}.acf\"
    relocate \"co.aikar.locales\", \"com.spectrasonic.${PROJECT_NAME}.locales\"
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
    filteringCharset \"UTF-8\"
    filesMatching(\"plugin.yml\") {
        expand props
    }
}" > build.gradle

printf "rootProject.name = '${PROJECT_NAME}'" > settings.gradle

mkdir -p "$PWD/src/main/resources"
mkdir -p "$PWD/src/main/java/com/spectrasonic/${PROJECT_NAME}/Utils"

printf "name: ${PROJECT_NAME}
version: '\${version}'
main: com.spectrasonic.${PROJECT_NAME}.Main
api-version: '${PAPERAPI_VERSION}'
authors: [Spectrasonic]
" > $PWD/src/main/resources/plugin.yml

printf "package com.spectrasonic.${PROJECT_NAME};

import com.spectrasonic.${PROJECT_NAME}.Utils.MessageUtils;
import org.bukkit.plugin.java.JavaPlugin;

public final class Main extends JavaPlugin {

    @Override
    public void onEnable() {

        registerCommands();
        registerEvents();
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
" > ${PWD}/src/main/java/com/spectrasonic/${PROJECT_NAME}/Main.java

printf "package com.spectrasonic.${PROJECT_NAME}.Utils;

import net.kyori.adventure.text.Component;
import net.kyori.adventure.text.minimessage.MiniMessage;
import org.bukkit.Bukkit;
import org.bukkit.command.CommandSender;
import org.bukkit.entity.Player;
import org.bukkit.plugin.java.JavaPlugin;

public final class MessageUtils {

    public static final String DIVIDER = \"<gray>----------------------------------------</gray>\";
    public static final String PREFIX = \"<gray>[<gold>${PROJECT_NAME}</gold>]</gray> <gold>»</gold> \";

    private static final MiniMessage miniMessage = MiniMessage.miniMessage();

    private MessageUtils() {
        // Private constructor to prevent instantiation
    }

    public static void sendMessage(CommandSender sender, String message) {
        sender.sendMessage(miniMessage.deserialize(PREFIX + message));
    }

    public static void sendConsoleMessage(String message) {
        Bukkit.getConsoleSender().sendMessage(miniMessage.deserialize(PREFIX + message));
    }

    public static void sendPermissionMessage(CommandSender sender) {
        sender.sendMessage(miniMessage.deserialize(PREFIX + \"<red>You do not have permission to use this command!</red>\"));
    }

    public static void sendStartupMessage(JavaPlugin plugin) {
        String[] messages = {
                DIVIDER,
                PREFIX + \"<white>\" + plugin.getDescription().getName() + \"</white> <green>Plugin Enabled!</green>\",
                PREFIX + \"<light_purple>Version: </light_purple>\" + plugin.getDescription().getVersion(),
                PREFIX + \"<white>Developed by: </white><red>\" + plugin.getDescription().getAuthors() + \"</red>\",
                DIVIDER
        };

        for (String message : messages) {
            Bukkit.getConsoleSender().sendMessage(miniMessage.deserialize(message));
        }
    }

    public static void sendVeiMessage(JavaPlugin plugin) {
        String[] messages = {
                PREFIX + \"⣇⣿⠘⣿⣿⣿⡿⡿⣟⣟⢟⢟⢝⠵⡝⣿⡿⢂⣼⣿⣷⣌⠩⡫⡻⣝⠹⢿⣿⣷\",
                PREFIX + \"⡆⣿⣆⠱⣝⡵⣝⢅⠙⣿⢕⢕⢕⢕⢝⣥⢒⠅⣿⣿⣿⡿⣳⣌⠪⡪⣡⢑⢝⣇\",
                PREFIX + \"⡆⣿⣿⣦⠹⣳⣳⣕⢅⠈⢗⢕⢕⢕⢕⢕⢈⢆⠟⠋⠉⠁⠉⠉⠁⠈⠼⢐⢕⢽\",
                PREFIX + \"⡗⢰⣶⣶⣦⣝⢝⢕⢕⠅⡆⢕⢕⢕⢕⢕⣴⠏⣠⡶⠛⡉⡉⡛⢶⣦⡀⠐⣕⢕\",
                PREFIX + \"⡝⡄⢻⢟⣿⣿⣷⣕⣕⣅⣿⣔⣕⣵⣵⣿⣿⢠⣿⢠⣮⡈⣌⠨⠅⠹⣷⡀⢱⢕\",
                PREFIX + \"⡝⡵⠟⠈⢀⣀⣀⡀⠉⢿⣿⣿⣿⣿⣿⣿⣿⣼⣿⢈⡋⠴⢿⡟⣡⡇⣿⡇⡀⢕\",
                PREFIX + \"⡝⠁⣠⣾⠟⡉⡉⡉⠻⣦⣻⣿⣿⣿⣿⣿⣿⣿⣿⣧⠸⣿⣦⣥⣿⡇⡿⣰⢗⢄\",
                PREFIX + \"⠁⢰⣿⡏⣴⣌⠈⣌⠡⠈⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣬⣉⣉⣁⣄⢖⢕⢕⢕\",
                PREFIX + \"⡀⢻⣿⡇⢙⠁⠴⢿⡟⣡⡆⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣵⣵⣿\",
                PREFIX + \"⡻⣄⣻⣿⣌⠘⢿⣷⣥⣿⠇⣿⣿⣿⣿⣿⣿⠛⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿\",
                PREFIX + \"⣷⢄⠻⣿⣟⠿⠦⠍⠉⣡⣾⣿⣿⣿⣿⣿⣿⢸⣿⣦⠙⣿⣿⣿⣿⣿⣿⣿⣿⠟\",
                PREFIX + \"⡕⡑⣑⣈⣻⢗⢟⢞⢝⣻⣿⣿⣿⣿⣿⣿⣿⠸⣿⠿⠃⣿⣿⣿⣿⣿⣿⡿⠁⣠\",
                PREFIX + \"⡝⡵⡈⢟⢕⢕⢕⢕⣵⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣶⣿⣿⣿⣿⣿⠿⠋⣀⣈⠙\",
                PREFIX + \"⡝⡵⡕⡀⠑⠳⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠛⢉⡠⡲⡫⡪⡪⡣\",
        };

        for (String message : messages) {
            Bukkit.getConsoleSender().sendMessage(miniMessage.deserialize(message));
        }
    }

    public static void sendBroadcastMessage(String message) {
        for (Player player : Bukkit.getOnlinePlayers()) {
            player.sendMessage(miniMessage.deserialize(message));
        }
    }

    public static void sendShutdownMessage(JavaPlugin plugin) {
        String[] messages = {
                DIVIDER,
                PREFIX + \"<red>\" + plugin.getDescription().getName() + \" plugin Disabled!</red>\",
                DIVIDER
        };

        for (String message : messages) {
            Bukkit.getConsoleSender().sendMessage(miniMessage.deserialize(message));
        }
    }
}
" > ${PWD}/src/main/java/com/spectrasonic/${PROJECT_NAME}/Utils/MessageUtils.java

printf "package com.spectrasonic.${PROJECT_NAME}.Utils;

import org.bukkit.Bukkit;
import org.bukkit.Sound;
import org.bukkit.SoundCategory;
import org.bukkit.entity.Player;
import org.bukkit.plugin.java.JavaPlugin;

public final class SoundUtils {

    private SoundUtils() {
        // Private constructor to prevent instantiation
    }

    public static void playerSound(Player player, Sound sound, float volume, float pitch) {
        player.playSound(player, sound, SoundCategory.MASTER, volume, pitch);
    }

    public static void broadcastPlayerSound(Sound sound, float volume, float pitch) {
        for (Player player : Bukkit.getOnlinePlayers()) {
            player.playSound(player, sound, SoundCategory.MASTER, volume, pitch);
        }
    }
}
" > ${PWD}/src/main/java/com/spectrasonic/${PROJECT_NAME}/Utils/SoundUtils.java

clear
echo "Project: ${MAGENTA}${PROJECT_NAME}${RESET} created successfully.${RESET}"
echo "Compiler: ${CYAN}Gradle${RESET}"
echo "Paper: ${MAGENTA}${PAPERAPI_VERSION}"