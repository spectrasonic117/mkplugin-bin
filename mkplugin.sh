#!/usr/bin/env sh
printf "

███╗   ███╗██╗  ██╗██████╗ ██╗     ██╗   ██╗ ██████╗ ██╗███╗   ██╗
████╗ ████║██║ ██╔╝██╔══██╗██║     ██║   ██║██╔════╝ ██║████╗  ██║
██╔████╔██║█████╔╝ ██████╔╝██║     ██║   ██║██║  ███╗██║██╔██╗ ██║
██║╚██╔╝██║██╔═██╗ ██╔═══╝ ██║     ██║   ██║██║   ██║██║██║╚██╗██║
██║ ╚═╝ ██║██║  ██╗██║     ███████╗╚██████╔╝╚██████╔╝██║██║ ╚████║
╚═╝     ╚═╝╚═╝  ╚═╝╚═╝     ╚══════╝ ╚═════╝  ╚═════╝ ╚═╝╚═╝  ╚═══╝

Developed by Spectrasonic
v1.1.2

"
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

commandapi_content=$(curl -s "https://central.sonatype.com/artifact/dev.jorel/commandapi")
COMANDAPI_VERSION=$(echo "$commandapi_content" | grep -oE 'pkg:maven/dev.jorel/commandapi@([0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9]+)?)' | sed 's/.*@//' | head -n 1)

PAPERWEIGHT_VERSION=$(curl -s https://plugins.gradle.org/plugin/io.papermc.paperweight.userdev | grep -o 'Version [0-9.]*-beta.[0-9]*' | head -n 1 | sed 's/Version //')

PAPERAPI_VERSION="1.21.1"
API_VERSION="1.21"
ACF_VERSION="0.5.1"
COMANDAPI_VERSION="10.1.2"
# LOMBOK_VERSION="1.18.36"
# MINIMESSAGE_VERSION="4.18.0"
JAVA_VERSION="21"
# GRADLE_SHADOW_VERSION="9.0.0-beta8"
PLUGIN_VERSION="1.0.0"
MAVEN_COMPILE_VERSION="3.14.0"
MAVEN_SHADOW_VERSION="3.6.0"
MAVEN_RESOURCES_VERSION="3.3.1"

AUTHOR="spectrasonic"

COMPILER_SET=false

# === Directories ===

BASE_DIR="src/main"
RESOURCES_DIR="${BASE_DIR}/resources"
JAVA_DIR="${BASE_DIR}/java/com/${AUTHOR}/${PROJECT_NAME}"
TEMPLATES_DIR="/opt/mkplugin/templates"

# Parse arguments
if [ $# -eq 0 ]; then
    # No args, prompt for both
    :
elif [ $# -eq 1 ]; then
    # Only project name, prompt for compiler
    PROJECT_NAME="$1"
elif [ $# -eq 2 ]; then
    # Project name and compiler
    PROJECT_NAME="$1"
    case $2 in
        gradle)
            COMPILER="gradle"
            COMPILER_SET=true
            ;;
        maven)
            COMPILER="maven"
            COMPILER_SET=true
            ;;
        *)
            echo "${RED}Compilador desconocido: $2. Usa 'gradle' o 'maven'."
            exit 1
            ;;
    esac
elif [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    echo "${RED}Uso:"
    echo "${GREEN}mkplugin ${BLUE}<project-name> ${YELLOW}[gradle|maven]"
    exit 1
else
    echo "${RED}Demasiados argumentos. Uso: mkplugin <project-name> [gradle|maven]"
    exit 1
fi

if [ "$COMPILER_SET" = false ]; then
    echo "${YELLOW}Select Compiler Project: ${RESET}"
    echo
    options=("maven" "gradle")
    select_option "${options[@]}"
    choice=$?
    COMPILER="${options[$choice]}"
fi

if [ -z "$PROJECT_NAME" ]; then
    read -p "${BMAGENTA}${BLACK} Plugin Project:${RESET} " PROJECT_NAME
elif [ -d "$PROJECT_NAME" ]; then
    echo "${RED}El proyecto ya existe, ${WHITE}Usa otro nombre!"
    exit 1
fi

# Maven Project Config
if [ "$COMPILER" == "maven" ]; then
    echo "${RED}Maven Selected${RESET}"
    git clone git@github.com:spectrasonic117/mkplugin.git -q "$PWD/$PROJECT_NAME" --depth=1 --branch maven
    cd "$PWD/$PROJECT_NAME"
    cp "$TEMPLATES_DIR/pom-template.xml" pom.xml
    sed -i '' "s|\${AUTHOR}|$AUTHOR|g" pom.xml
    sed -i '' "s|\${PROJECT_NAME}|$PROJECT_NAME|g" pom.xml
    sed -i '' "s|\${PLUGIN_VERSION}|$PLUGIN_VERSION|g" pom.xml
    sed -i '' "s|\${JAVA_VERSION}|$JAVA_VERSION|g" pom.xml
    sed -i '' "s|\${PAPERAPI_VERSION}|$PAPERAPI_VERSION|g" pom.xml
    sed -i '' "s|\${COMANDAPI_VERSION}|$COMANDAPI_VERSION|g" pom.xml
    sed -i '' "s|\${LOMBOK_VERSION}|$LOMBOK_VERSION|g" pom.xml
    sed -i '' "s|\${MINIMESSAGE_VERSION}|$MINIMESSAGE_VERSION|g" pom.xml
    sed -i '' "s|\${MAVEN_COMPILE_VERSION}|$MAVEN_COMPILE_VERSION|g" pom.xml
    sed -i '' "s|\${MAVEN_SHADOW_VERSION}|$MAVEN_SHADOW_VERSION|g" pom.xml
    sed -i '' "s|\${MAVEN_RESOURCES_VERSION}|$MAVEN_RESOURCES_VERSION|g" pom.xml


# Gradle Project Config
elif [ "$COMPILER" == "gradle" ]; then
    echo "${CYAN}Gradle Selected${RESET}"
    git clone git@github.com:spectrasonic117/mkplugin.git -q "$PWD/$PROJECT_NAME" --depth=1 --branch gradle
    cd "$PWD/$PROJECT_NAME"

    # gradle.properties
    printf "org.gradle.caching=true
org.gradle.parallel=true
org.gradle.configuration-cache=true
org.gradle.daemon=true

# Vars

version=1.0.0
group=com.spectrasonic
projectName=$PROJECT_NAME
javaVersion=21

# Var Plugins
gradlePaperweight=$PAPERWEIGHT_VERSION
gradleShadow=$GRADLE_SHADOW_VERSION

# Dependencies Vars
minecraftVersion=$PAPERAPI_VERSION
CommandAPI=$COMANDAPI_VERSION
Lombok=$LOMBOK_VERSION
Minimessage=$MINIMESSAGE_VERSION" > gradle.properties

    cp "$TEMPLATES_DIR/build-template.gradle" build.gradle
    # sed -i '' "s|\${AUTHOR}|$AUTHOR|g" build.gradle
    # sed -i '' "s|\${PROJECT_NAME}|$PROJECT_NAME|g" build.gradle
    # sed -i '' "s|\${PLUGIN_VERSION}|$PLUGIN_VERSION|g" build.gradle
    # sed -i '' "s|\${PAPERWEIGHT_VERSION}|$PAPERWEIGHT_VERSION|g" build.gradle
    # sed -i '' "s|\${GRADLE_SHADOW_VERSION}|$GRADLE_SHADOW_VERSION|g" build.gradle
    # sed -i '' "s|\${PAPERAPI_VERSION}|$PAPERAPI_VERSION|g" build.gradle
    # sed -i '' "s|\${COMANDAPI_VERSION}|$COMANDAPI_VERSION|g" build.gradle
    # sed -i '' "s|\${LOMBOK_VERSION}|$LOMBOK_VERSION|g" build.gradle
    # sed -i '' "s|\${MINIMESSAGE_VERSION}|$MINIMESSAGE_VERSION|g" build.gradle
    # sed -i '' "s|\${JAVA_VERSION}|$JAVA_VERSION|g" build.gradle

    # Settings.gradle
    cp "$TEMPLATES_DIR/settings-template.gradle" settings.gradle
    sed -i '' "s|\${PROJECT_NAME}|$PROJECT_NAME|g" settings.gradle

fi

# Download Paper Agent
command curl https://gitlab.com/Spectrasonic/agents/-/raw/master/minecraft/plugin-agent.md -o ${PWD}/AGENTS.md

# Save Files
mkdir -p "$PWD/src/main/resources"
mkdir -p "$PWD/src/main/java/com/${AUTHOR}/${PROJECT_NAME}"/{managers,commands,events,listeners,enums}

cp "$TEMPLATES_DIR/plugin-template.yml" "$PWD/src/main/resources/plugin.yml"
sed -i '' "s|\${PROJECT_NAME}|$PROJECT_NAME|g" "$PWD/src/main/resources/plugin.yml"
sed -i '' "s|\${AUTHOR}|$AUTHOR|g" "$PWD/src/main/resources/plugin.yml"
sed -i '' "s|\${API_VERSION}|$API_VERSION|g" "$PWD/src/main/resources/plugin.yml"

touch "$PWD/src/main/resources/config.yml"

cp "$TEMPLATES_DIR/Main-template.java" "${PWD}/src/main/java/com/${AUTHOR}/${PROJECT_NAME}/Main.java"
sed -i '' "s|\${AUTHOR}|$AUTHOR|g" "${PWD}/src/main/java/com/${AUTHOR}/${PROJECT_NAME}/Main.java"
sed -i '' "s|\${PROJECT_NAME}|$PROJECT_NAME|g" "${PWD}/src/main/java/com/${AUTHOR}/${PROJECT_NAME}/Main.java"

cp "$TEMPLATES_DIR/CommandManager-template.java" "$PWD/src/main/java/com/${AUTHOR}/${PROJECT_NAME}/managers/CommandManager.java"
sed -i '' "s|\${AUTHOR}|$AUTHOR|g" "$PWD/src/main/java/com/${AUTHOR}/${PROJECT_NAME}/managers/CommandManager.java"
sed -i '' "s|\${PROJECT_NAME}|$PROJECT_NAME|g" "$PWD/src/main/java/com/${AUTHOR}/${PROJECT_NAME}/managers/CommandManager.java"

cp "$TEMPLATES_DIR/EventManager-template.java" "$PWD/src/main/java/com/${AUTHOR}/${PROJECT_NAME}/managers/EventManager.java"
sed -i '' "s|\${AUTHOR}|$AUTHOR|g" "$PWD/src/main/java/com/${AUTHOR}/${PROJECT_NAME}/managers/EventManager.java"
sed -i '' "s|\${PROJECT_NAME}|$PROJECT_NAME|g" "$PWD/src/main/java/com/${AUTHOR}/${PROJECT_NAME}/managers/EventManager.java"

cp "$TEMPLATES_DIR/ConfigManager-template.java" "$PWD/src/main/java/com/${AUTHOR}/${PROJECT_NAME}/managers/ConfigManager.java"
sed -i '' "s|\${AUTHOR}|$AUTHOR|g" "$PWD/src/main/java/com/${AUTHOR}/${PROJECT_NAME}/managers/ConfigManager.java"
sed -i '' "s|\${PROJECT_NAME}|$PROJECT_NAME|g" "$PWD/src/main/java/com/${AUTHOR}/${PROJECT_NAME}/managers/ConfigManager.java"


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
