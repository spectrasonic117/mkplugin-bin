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
JAVA_DIR="${BASE_DIR}/java/com/${AUTHOR}/${PROJECT_NAME}/Utils"

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
mkdir -p "$PWD/src/main/java/com/${AUTHOR}/${PROJECT_NAME}/Utils"

printf "name: ${PROJECT_NAME}
version: '\${version}'
    main: com.${AUTHOR}.${PROJECT_NAME}.Main
api-version: '${API_VERSION}'
authors: [Spectrasonic]
" > $PWD/src/main/resources/plugin.yml

    printf "package com.${AUTHOR}.${PROJECT_NAME};

    import com.${AUTHOR}.${PROJECT_NAME}.Utils.MessageUtils;
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
" > ${PWD}/src/main/java/com/${AUTHOR}/${PROJECT_NAME}/Main.java

printf "package com.${AUTHOR}.${PROJECT_NAME}.Utils;

import net.kyori.adventure.text.Component;
import net.kyori.adventure.text.minimessage.MiniMessage;
import net.kyori.adventure.title.Title;
import net.kyori.adventure.title.Title.Times;
import org.bukkit.Bukkit;
import org.bukkit.command.CommandSender;
import org.bukkit.entity.Player;
import org.bukkit.plugin.java.JavaPlugin;
import java.time.Duration;

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
        Bukkit.getOnlinePlayers().forEach(player -> 
            player.sendMessage(miniMessage.deserialize(message))
        );
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

    public static void sendTitle(Player player, String title, String subtitle, int fadeIn, int stay, int fadeOut) {
        final Component titleComponent = miniMessage.deserialize(title);
        final Component subtitleComponent = miniMessage.deserialize(subtitle);
        player.showTitle(Title.title(titleComponent, subtitleComponent, Times.times(
            Duration.ofSeconds(fadeIn),
            Duration.ofSeconds(stay),
            Duration.ofSeconds(fadeOut)
        )));
    }

    public static void sendActionBar(Player player, String message) {
        player.sendActionBar(miniMessage.deserialize(message));
    }

    public static void broadcastTitle(String title, String subtitle, int fadeIn, int stay, int fadeOut) {
        final Component titleComponent = miniMessage.deserialize(title);
        final Component subtitleComponent = miniMessage.deserialize(subtitle);
        final Title formattedTitle = Title.title(titleComponent, subtitleComponent, Times.times(
            Duration.ofSeconds(fadeIn),
            Duration.ofSeconds(stay),
            Duration.ofSeconds(fadeOut)
        ));

        Bukkit.getOnlinePlayers().forEach(player -> player.showTitle(formattedTitle));
    }

        // Uso - Send Title to players
        // MiniMessageUtils.sendTitle(player, 
        //     \"<gold>¡Alerta!</gold>\", 
        //     \"<red>Mensaje importante</red>\", 
        //     2, 40, 2
        // );

    public static void broadcastActionBar(String message) {
        final Component component = miniMessage.deserialize(message);
        Bukkit.getOnlinePlayers().forEach(player -> player.sendActionBar(component));
    }

    // Uso Broadcast ActionBAR
    // MiniMessageUtils.broadcastActionBar(\"<yellow>¡Evento e…special activado!</yellow>\");

}
" > ${PWD}/src/main/java/com/${AUTHOR}/${PROJECT_NAME}/Utils/MessageUtils.java

printf "package com.${AUTHOR}.${PROJECT_NAME}.Utils;

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
        Bukkit.getOnlinePlayers().forEach(player -> 
            player.playSound(player, sound, SoundCategory.MASTER, volume, pitch)
        );
    }
}
" > ${PWD}/src/main/java/com/${AUTHOR}/${PROJECT_NAME}/Utils/SoundUtils.java

printf "package com.${AUTHOR}.${PROJECT_NAME}.Utils;

import net.kyori.adventure.text.minimessage.MiniMessage;
import org.bukkit.Material;
import org.bukkit.NamespacedKey;
import org.bukkit.enchantments.Enchantment;
import org.bukkit.inventory.ItemFlag;
import org.bukkit.inventory.ItemStack;
import org.bukkit.inventory.meta.ItemMeta;

import java.util.HashSet;
import java.util.Set;

public class ItemBuilder {
    private final ItemStack item;
    private final ItemMeta meta;
    private final Set<ItemFlag> flags = new HashSet<>();

    public static ItemBuilder setMaterial(String materialName) {
        Material material = Material.matchMaterial(materialName.toUpperCase());
        if (material == null) throw new IllegalArgumentException(\"Invalid material: \" + materialName);
        return new ItemBuilder(material);
    }

    private ItemBuilder(Material material) {
        this.item = new ItemStack(material);
        this.meta = item.getItemMeta();
    }

    public ItemBuilder setName(String name) {
        meta.displayName(MiniMessage.miniMessage().deserialize(name));
        return this;
    }

    public ItemBuilder setLore(String... loreLines) {
        meta.lore(java.util.Arrays.stream(loreLines)
                .map(MiniMessage.miniMessage()::deserialize)
                .toList());
        return this;
    }

    public ItemBuilder setCustomModelData(int customModelData) {
        meta.setCustomModelData(customModelData);
        return this;
    }

    public ItemBuilder addEnchantment(String enchantmentName, int level) {
        String normalized = enchantmentName.toUpperCase().toLowerCase();
        Enchantment enchantment = Enchantment.getByKey(NamespacedKey.minecraft(normalized));
        if (enchantment == null) {
            throw new IllegalArgumentException(\"Invalid enchantment name: \" + enchantmentName);
        }
        meta.addEnchant(enchantment, level, true);
        return this;
    }

    public ItemBuilder setFlag(String flagName) {
        try {
            ItemFlag flag = ItemFlag.valueOf(flagName.toUpperCase().replace(\" \", \"_\"));
            flags.add(flag);
            return this;
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException(\"Invalid flag: \" + flagName);
        }
    }

    public ItemBuilder setUnbreakable(boolean unbreakable) {
        meta.setUnbreakable(unbreakable);
        return this;
    }

    public ItemStack build() {
        meta.addItemFlags(flags.toArray(new ItemFlag[0]));
        item.setItemMeta(meta);
        return item;
    }
}" > ${PWD}/src/main/java/com/${AUTHOR}/${PROJECT_NAME}/Utils/ItemBuilder.java

# Git Commands
command git add .
command git commit -m "🌱 - Initial commit"
command git checkout -b dev

echo " "
# Print Project Info
echo "Project: ${MAGENTA}${PROJECT_NAME}${RESET} created successfully.${RESET}"
echo "Compiler: ${CYAN}Gradle${RESET}"
echo "Paper: ${MAGENTA}${PAPERAPI_VERSION}"