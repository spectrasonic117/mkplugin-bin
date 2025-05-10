#!/usr/bin/env sh

# ███╗   ███╗██╗  ██╗██████╗ ██╗     ██╗   ██╗ ██████╗ ██╗███╗   ██╗
# ████╗ ████║██║ ██╔╝██╔══██╗██║     ██║   ██║██╔════╝ ██║████╗  ██║
# ██╔████╔██║█████╔╝ ██████╔╝██║     ██║   ██║██║  ███╗██║██╔██╗ ██║
# ██║╚██╔╝██║██╔═██╗ ██╔═══╝ ██║     ██║   ██║██║   ██║██║██║╚██╗██║
# ██║ ╚═╝ ██║██║  ██╗██║     ███████╗╚██████╔╝╚██████╔╝██║██║ ╚████║
# ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝     ╚══════╝ ╚═════╝  ╚═════╝ ╚═╝╚═╝  ╚═══╝

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



function select_option {

    # little helpers for terminal print control and key input
    ESC=$( printf "\033")
    cursor_blink_on()  { printf "$ESC[?25h"; }
    cursor_blink_off() { printf "$ESC[?25l"; }
    cursor_to()        { printf "$ESC[$1;${2:-1}H"; }
    print_option()     { printf "   $1 "; }
    print_selected()   { printf "  $ESC[7m $1 $ESC[27m"; }
    get_cursor_row()   { IFS=';' read -sdR -p $'\E[6n' ROW COL; echo ${ROW#*[}; }
    key_input()        { read -s -n3 key 2>/dev/null >&2
                         if [[ $key = $ESC[A ]]; then echo up;    fi
                         if [[ $key = $ESC[B ]]; then echo down;  fi
                         if [[ $key = ""     ]]; then echo enter; fi; }

    # initially print empty new lines (scroll down if at bottom of screen)
    for opt; do printf "\n"; done

    # determine current screen position for overwriting the options
    local lastrow=`get_cursor_row`
    local startrow=$(($lastrow - $#))

    # ensure cursor and input echoing back on upon a ctrl+c during read -s
    trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
    cursor_blink_off

    local selected=0
    while true; do
        # print options by overwriting the last lines
        local idx=0
        for opt; do
            cursor_to $(($startrow + $idx))
            if [ $idx -eq $selected ]; then
                print_selected "$opt"
            else
                print_option "$opt"
            fi
            ((idx++))
        done

        # user key control
        case `key_input` in
            enter) break;;
            up)    ((selected--));
                    if [ $selected -lt 0 ]; then selected=$(($# - 1)); fi;;
            down)  ((selected++));
                    if [ $selected -ge $# ]; then selected=0; fi;;
        esac
    done

    # cursor position back to normal
    cursor_to $lastrow
    printf "\n"
    cursor_blink_on

    return $selected
}

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

echo "${YELLOW}Select Compiler Project: ${RESET}"
echo
options=("maven" "gradle")
select_option "${options[@]}"
choice=$?
COMPILER="${options[$choice]}"

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

if [ "$COMPILER" == "maven" ]; then
    echo "${RED}Maven Selected${RESET}"
    git clone git@github.com:spectrasonic117/mkplugin.git -q $PWD/$PROJECT_NAME --depth=1 --branch maven
    cd $PWD/$PROJECT_NAME
    printf "<project xmlns=\"http://maven.apache.org/POM/4.0.0\"
            xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"
            xsi:schemaLocation=\"http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd\">
        <modelVersion>4.0.0</modelVersion>

        <groupId>com.${AUTHOR}</groupId>
        <artifactId>${PROJECT_NAME}</artifactId>
        <version>${PLUGIN_VERSION}</version>
        <packaging>jar</packaging>

        <properties>
            <maven.compiler.source>${JAVA_VERSION}</maven.compiler.source>
            <maven.compiler.target>${JAVA_VERSION}</maven.compiler.target>
            <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
            <paper.version>${PAPERAPI_VERSION}-R0.1-SNAPSHOT</paper.version>
            <acf.version>${ACF_VERSION}-SNAPSHOT</acf.version>
            <lombok.version>${LOMBOK_VERSION}</lombok.version>
            <adventure.version>4.21.0</adventure.version>
        </properties>

        <repositories>
            <repository>
                <id>papermc-repo</id>
                <url>https://repo.papermc.io/repository/maven-public/</url>
            </repository>
            <repository>
                <id>sonatype</id>
                <url>https://oss.sonatype.org/content/groups/public/</url>
            </repository>
            <repository>
                <id>aikar</id>
                <url>https://repo.aikar.co/content/groups/aikar/</url>
            </repository>
        </repositories>

        <dependencies>
            <dependency>
                <groupId>io.papermc.paperweight.userdev</groupId>
                <artifactId>io.papermc.paperweight.userdev.gradle.plugin</artifactId>
                <version>2.0.0-beta.16</version>
                <type>pom</type>
            </dependency>

            <!-- ACF Aikar -->
            <dependency>
                <groupId>co.aikar</groupId>
                <artifactId>acf-paper</artifactId>
                <version>$\{acf.version}</version>
            </dependency>

            <!-- Lombok -->
            <dependency>
                <groupId>org.projectlombok</groupId>
                <artifactId>lombok</artifactId>
                <version>$\{lombok.version}</version>
                <scope>provided</scope>
            </dependency>

            <!-- Adventure Minimessage -->
            <dependency>
                <groupId>net.kyori</groupId>
                <artifactId>adventure-text-minimessage</artifactId>
                <version>$\{adventure.version}</version>
            </dependency>
            <dependency>
                <groupId>net.kyori</groupId>
                <artifactId>adventure-api</artifactId>
                <version>$\{adventure.version}</version>
            </dependency>
        </dependencies>

        <build>
            <plugins>
                <!-- Compiler plugin para Java 21 -->
                <plugin>
                    <artifactId>maven-compiler-plugin</artifactId>
                    <version>3.11.0</version>
                    <configuration>
                        <source>$\{maven.compiler.source}</source>
                        <target>$\{maven.compiler.target}</target>
                        <encoding>$\{project.build.sourceEncoding}</encoding>
                        <release>21</release>
                    </configuration>
                </plugin>

                <!-- Shade plugin para crear el JAR y hacer relocaciones -->
                <plugin>
                    <groupId>org.apache.maven.plugins</groupId>
                    <artifactId>maven-shade-plugin</artifactId>
                    <version>3.6.0</version>
                    <configuration>
                                <dependencyReducedPomLocation>$\{project.build.directory}/dependency-reduced-pom.xml</dependencyReducedPomLocation>
                                <relocations>
                                    <relocation>
                                        <pattern>co.aikar.commands</pattern>
                                        <shadedPattern.${AUTHOR}.acf</shadedPattern>
                                    </relocation>
                                    <relocation>
                                        <pattern>co.aikar.locales</pattern>
                                        <shadedPattern.${AUTHOR}.locales</shadedPattern>
                                    </relocation>
                                </relocations>
                            </configuration>
                    <executions>
                        <execution>
                            <phase>package</phase>
                            <goals>
                                <goal>shade</goal>
                            </goals>
                        </execution>
                    </executions>
                </plugin>

                <!-- Procesamiento de resources para expandir variables en plugin.yml -->
                <plugin>
                    <artifactId>maven-resources-plugin</artifactId>
                    <version>3.3.1</version>
                    <configuration>
                        <encoding>$\{project.build.sourceEncoding}</encoding>
                        <delimiters>
                            <delimiter>$\{*}</delimiter>
                        </delimiters>
                        <useDefaultDelimiters>false</useDefaultDelimiters>
                        <nonFilteredFileExtensions>
                            <nonFilteredFileExtension>jar</nonFilteredFileExtension>
                        </nonFilteredFileExtensions>
                    </configuration>
                </plugin>
                <plugin>
                    <groupId>org.apache.maven.plugins</groupId>
                    <artifactId>maven-compiler-plugin</artifactId>
                    <configuration>
                        <annotationProcessorPaths>
                            <path>
                                <groupId>org.projectlombok</groupId>
                                <artifactId>lombok</artifactId>
                                <version>$\{lombok.version}</version>
                            </path>
                        </annotationProcessorPaths>
                    </configuration>
                </plugin>
            </plugins>
        </build>
    </project>" > pom.xml

elif [ "$COMPILER" == "gradle" ]; then
    echo "${CYAN}Gradle Selected${RESET}"
    git clone git@github.com:spectrasonic117/mkplugin.git -q $PWD/$PROJECT_NAME --depth=1
    cd $PWD/$PROJECT_NAME

    # build.Gradle
    printf "plugins {
        id(\"io.papermc.paperweight.userdev\") version \"2.0.0-beta.14\"
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
        // compileOnly(\"io.papermc.paper:paper-api:${PAPERAPI_VERSION}-R0.1-SNAPSHOT\") // Paper
        paperweight.paperDevBundle(\"${PAPERAPI_VERSION}-R0.1-SNAPSHOT\")

        // ACF Aikar
        implementation \"co.aikar:acf-paper:${ACF_VERSION}-SNAPSHOT\"

        // Lombok
        compileOnly \"org.projectlombok:lombok:${LOMBOK_VERSION}\"
        annotationProcessor \"org.projectlombok:lombok:${LOMBOK_VERSION}\"

        // Minimessage - Adventure
        implementation \"net.kyori:adventure-text-minimessage:${MINIMESSAGE_VERSION}\"
        implementation \"net.kyori:adventure-api:${MINIMESSAGE_VERSION}\"
    }

    shadowJar {
        relocate \"co.aikar.commands\", \"com.${AUTHOR}.${PROJECT_NAME}.acf\"
        relocate \"co.aikar.locales\", \"com.${AUTHOR}.${PROJECT_NAME}.locales\"
        destinationDirectory = file(\"\${rootDir}/out\")
        archiveFileName = \"\${rootProject.name}-\${version}.jar\" 
    }

    build.dependsOn shadowJar
    build.finalizedBy reobfJar

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
    //      options.encoding = \"UTF-8\"
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

fi


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
}" > ${PWD}/src/main/java/com/${AUTHOR}/${PROJECT_NAME}/Main.java

if [ -d .git ]; then
    command rm -rf .git/
fi

command git init -q

# Git Commands
command git add .
command git commit -m "🌱 - Initial commit"
command git checkout -b dev

echo " "
# Print Project Info
echo "Project: ${MAGENTA}${PROJECT_NAME}${RESET} created successfully.${RESET}"
echo "Compiler: ${CYAN}${COMPILER}${RESET}"
echo "Paper: ${MAGENTA}${PAPERAPI_VERSION}"