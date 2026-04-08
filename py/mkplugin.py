#!/usr/bin/env python3

"""mkplugin - Python rewrite of the original mkplugin.sh script.

This script creates a new Minecraft plugin project based on templates.
It mirrors the functionality of the original Bash version, but is
implemented in Python for better readability and maintainability.
"""

import os
import sys
import subprocess
import urllib.request
import re
import shutil
from pathlib import Path

# --- Color constants for terminal output (using ANSI escape codes) ---
BLACK = "\033[30m"
RED = "\033[31m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
BLUE = "\033[34m"
MAGENTA = "\033[35m"
CYAN = "\033[36m"
WHITE = "\033[37m"
RESET = "\033[0m"
BOLD = "\033[1m"
UNDERLINE = "\033[4m"

# --- Helper functions -----------------------------------------------------


def fetch_latest_version(url: str, regex: str) -> str:
    """Retrieve the first version matching *regex* from *url*.

    Args:
        url: The URL to fetch.
        regex: Regular expression containing a capture group for the version.

    Returns:
        The first captured version string, or an empty string on failure.
    """
    try:
        with urllib.request.urlopen(url) as response:
            content = response.read().decode("utf-8", errors="ignore")
    except Exception as e:
        print(f"{RED}Error fetching {url}: {e}{RESET}")
        return ""
    match = re.search(regex, content)
    return match.group(1) if match else ""


def select_option(options):
    """Present a list of *options* and return the selected index.

    The original Bash version uses arrow‑key navigation. To keep the
    script simple and portable we ask the user to type the number of the
    desired option.
    """
    for i, opt in enumerate(options, start=1):
        print(f"{GREEN}{i}) {opt}{RESET}")
    while True:
        choice = input(f"{YELLOW}Select an option (1-{len(options)}): {RESET}")
        if not choice.isdigit():
            continue
        idx = int(choice) - 1
        if 0 <= idx < len(options):
            return idx


def replace_placeholders(file_path: Path, mapping: dict):
    """Replace placeholders like ${PLACEHOLDER} in *file_path*.

    *mapping* is a dict where keys are placeholder names without the ${}.
    The function overwrites the file in‑place.
    """
    text = file_path.read_text(encoding="utf-8")
    for key, value in mapping.items():
        placeholder = f"${{{key}}}"
        text = text.replace(placeholder, value)
    file_path.write_text(text, encoding="utf-8")


def run_cmd(cmd, cwd=None, capture_output=False):
    """Execute *cmd* via subprocess.

    Returns the completed Process object. If *capture_output* is True, the
    stdout/stderr are captured and returned as text.
    """
    result = subprocess.run(
        cmd,
        shell=True,
        cwd=cwd,
        text=True,
        capture_output=capture_output,
        check=False,
    )
    return result


def main():
    # Print banner
    banner = f"""
{BLUE} ███╗   ███╗██╗  ██╗██████╗ ██╗     ██╗   ██╗ ██████╗ ██╗███╗   ██╗
{BLUE} ████╗ ████║██║ ██╔╝██╔══██╗██║     ██║   ██║██╔════╝ ██║████╗  ██║
{BLUE} ██╔████╔██║█████╔╝ ██████╔╝██║     ██║   ██║██║  ███╗██║██╔██╗ ██║
{BLUE} ██║╚██╔╝██║██╔═██╗ ██╔═══╝ ██║     ██║   ██║██║   ██║██║██║╚██╗██║
{BLUE} ██║ ╚═╝ ██║██║  ██╗██║     ███████╗╚██████╔╝╚██████╔╝██║██║ ╚████║
{BLUE} ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝     ╚══════╝ ╚═════╝  ╚═════╝ ╚═╝╚═╝  ╚═══╝

{WHITE}Developed by {RED}spectrasonic{RESET}
{GREEN}v1.1.4{RESET}
"""
    print(banner)

    # --- Versions -------------------------------------------------------
    advent_url = (
        "https://central.sonatype.com/artifact/net.kyori/adventure-text-minimessage"
    )
    minimessage_version = fetch_latest_version(
        advent_url,
        r"pkg:maven/net\.kyori/adventure-text-minimessage@([0-9]+\.[0-9]+\.[0-9]+)",
    )

    lombok_url = "https://central.sonatype.com/artifact/org.projectlombok/lombok"
    lombok_version = fetch_latest_version(
        lombok_url,
        r"pkg:maven/org\.projectlombok/lombok@([0-9]+\.[0-9]+\.[0-9]+)",
    )

    shadow_url = (
        "https://central.sonatype.com/artifact/com.gradleup.shadow/shadow-gradle-plugin"
    )
    gradle_shadow_version = fetch_latest_version(
        shadow_url,
        r"pkg:maven/com\.gradleup\.shadow/shadow-gradle-plugin@([0-9]+\.[0-9]+\.[0-9]+(?:-[a-zA-Z0-9]+)?)",
    )

    commandapi_url = "https://central.sonatype.com/artifact/dev.jorel/commandapi"
    commandapi_version = fetch_latest_version(
        commandapi_url,
        r"pkg:maven/dev\.jorel/commandapi@([0-9]+\.[0-9]+\.[0-9]+(?:-[a-zA-Z0-9]+)?)",
    )

    paperweight_version = fetch_latest_version(
        "https://plugins.gradle.org/plugin/io.papermc.paperweight.userdev",
        r"Version ([0-9.]+-beta\.[0-9]+)",
    )

    # Fixed values from original script
    ACF_VERSION = "0.5.1"
    JAVA_VERSION = "21"
    PLUGIN_VERSION = "1.0.0"
    MAVEN_COMPILE_VERSION = "3.14.0"
    MAVEN_SHADOW_VERSION = "3.6.0"
    MAVEN_RESOURCES_VERSION = "3.3.1"
    AUTHOR = "spectrasonic"

    compiler_set = False
    project_name = None
    compiler = None

    # --- Argument parsing ------------------------------------------------
    args = sys.argv[1:]
    if len(args) == 0:
        # Will prompt for both project name and compiler later
        pass
    elif len(args) == 1:
        project_name = args[0]
    elif len(args) == 2:
        project_name = args[0]
        comp_arg = args[1].lower()
        if comp_arg == "gradle":
            compiler = "gradle"
            compiler_set = True
        elif comp_arg == "maven":
            compiler = "maven"
            compiler_set = True
        else:
            print(
                f"{RED}Compilador desconocido: {comp_arg}. Usa 'gradle' o 'maven'.{RESET}"
            )
            sys.exit(1)
    elif args[0] in ("--help", "-h"):
        print(
            f"{RED}Uso:{RESET}\n{GREEN}mkplugin {BLUE}<project-name> {YELLOW}[gradle|maven]{RESET}"
        )
        sys.exit(0)
    else:
        print(
            f"{RED}Demasiados argumentos. Uso: mkplugin <project-name> [gradle|maven]{RESET}"
        )
        sys.exit(1)

    # Prompt for compiler if not set
    if not compiler_set:
        print(f"{YELLOW}Select Compiler Project:{RESET}\n")
        compiler_options = ["maven", "gradle"]
        choice = select_option(compiler_options)
        compiler = compiler_options[choice]

    # Prompt for project name if missing
    if not project_name:
        project_name = input(f"{MAGENTA}{BLACK} Plugin Project:{RESET} ").strip()
    elif os.path.isdir(project_name):
        print(f"{RED}El proyecto ya existe, {WHITE}Usa otro nombre!{RESET}")
        sys.exit(1)

    # --- Minecraft version selection ------------------------------------
    print(f"{YELLOW}Select Minecraft Version:{RESET}\n")
    mc_options = [
        "1.20.1",
        "1.20.4",
        "1.21.1",
        "1.21.4",
        "1.21.8",
        "1.21.10",
        "1.21.11",
        "26.1 (Experimental)",
    ]
    mc_choice = select_option(mc_options)
    paperapi_version = mc_options[mc_choice]

    # Determine API version based on selected Minecraft version
    if paperapi_version.startswith("1.20"):
        api_version = "1.20"
    elif paperapi_version.startswith("1.21"):
        api_version = "1.21"
    elif paperapi_version.startswith("26"):
        print(f"{RED}Version experimental no Probada{RESET}")
        sys.exit(1)
    else:
        api_version = "1.21"

    # --- Paths -----------------------------------------------------------
    # Template directory – default mirrors the original install location.
    opt_dir = os.getenv("OPTDIR", "/opt")
    templates_dir = Path(opt_dir) / "mkplugin" / "templates"

    # Work within the newly created project directory
    project_path = Path.cwd() / project_name

    # --- Project creation -------------------------------------------------
    if compiler == "maven":
        print(f"{RED}Maven Selected{RESET}")
        # Clone the Maven branch of the template repo
        run_cmd(
            f"git clone git@github.com:spectrasonic117/mkplugin.git -q {project_path} --depth=1 --branch maven"
        )
        # Copy pom.xml template and replace placeholders
        pom_src = templates_dir / "pom-template.xml"
        pom_dest = project_path / "pom.xml"
        shutil.copy(pom_src, pom_dest)
        mapping = {
            "AUTHOR": AUTHOR,
            "PROJECT_NAME": project_name,
            "PLUGIN_VERSION": PLUGIN_VERSION,
            "JAVA_VERSION": JAVA_VERSION,
            "PAPERAPI_VERSION": paperapi_version,
            "COMANDAPI_VERSION": commandapi_version,
            "LOMBOK_VERSION": lombok_version,
            "MINIMESSAGE_VERSION": minimessage_version,
            "MAVEN_COMPILE_VERSION": MAVEN_COMPILE_VERSION,
            "MAVEN_SHADOW_VERSION": MAVEN_SHADOW_VERSION,
            "MAVEN_RESOURCES_VERSION": MAVEN_RESOURCES_VERSION,
        }
        replace_placeholders(pom_dest, mapping)
    elif compiler == "gradle":
        print(f"{CYAN}Gradle Selected{RESET}")
        run_cmd(
            f"git clone git@github.com:spectrasonic117/mkplugin.git -q {project_path} --depth=1 --branch gradle"
        )
        # Create gradle.properties file
        gradle_props = f"""org.gradle.caching=true
org.gradle.configuration-cache=true
org.gradle.configuration-cache.problems=warn
org.gradle.daemon=true
org.gradle.jvmargs=-Xmx2g -Dfile.encoding=UTF-8
org.gradle.parallel=false

version={PLUGIN_VERSION}
group=com.{AUTHOR}
projectName={project_name}
javaVersion={JAVA_VERSION}

gradlePaperweight={paperweight_version}
gradleShadow={gradle_shadow_version}

minecraftVersion={paperapi_version}
CommandAPI={commandapi_version}
Lombok={lombok_version}
Minimessage={minimessage_version}
"""
        (project_path / "gradle.properties").write_text(gradle_props, encoding="utf-8")
        # Copy build.gradle template
        shutil.copy(
            templates_dir / "build-template.gradle", project_path / "build.gradle"
        )
        # Copy and adjust settings.gradle
        shutil.copy(
            templates_dir / "settings-template.gradle", project_path / "settings.gradle"
        )
        replace_placeholders(
            project_path / "settings.gradle", {"PROJECT_NAME": project_name}
        )
    else:
        print(f"{RED}Compilador no reconocido: {compiler}{RESET}")
        sys.exit(1)

    # --- Common setup ----------------------------------------------------
    # Download PaperMC agent description
    agents_url = "https://gitlab.com/Spectrasonic/agents/-/raw/master/minecraft/papemc_plugin_agent-en.md"
    agents_path = project_path / "AGENTS.md"
    try:
        urllib.request.urlretrieve(agents_url, agents_path)
    except Exception as e:
        print(f"{RED}Failed to download agents file: {e}{RESET}")

    # Create source directories
    src_main = project_path / "src" / "main"
    resources_dir = src_main / "resources"
    java_base = src_main / "java" / "com" / AUTHOR / project_name
    (java_base / "managers").mkdir(parents=True, exist_ok=True)
    (java_base / "commands").mkdir(parents=True, exist_ok=True)
    (java_base / "events").mkdir(parents=True, exist_ok=True)
    (java_base / "listeners").mkdir(parents=True, exist_ok=True)
    (java_base / "enums").mkdir(parents=True, exist_ok=True)
    resources_dir.mkdir(parents=True, exist_ok=True)

    # Copy and process plugin.yml
    plugin_yml_src = templates_dir / "plugin-template.yml"
    plugin_yml_dest = resources_dir / "plugin.yml"
    shutil.copy(plugin_yml_src, plugin_yml_dest)
    replace_placeholders(
        plugin_yml_dest,
        {
            "PROJECT_NAME": project_name,
            "AUTHOR": AUTHOR,
            "API_VERSION": api_version,
        },
    )

    # Create empty config.yml
    (resources_dir / "config.yml").touch()

    # Copy Java class templates
    java_templates = {
        "Main-template.java": "Main.java",
        "CommandManager-template.java": "managers/CommandManager.java",
        "EventManager-template.java": "managers/EventManager.java",
        "ConfigManager-template.java": "managers/ConfigManager.java",
    }
    for src_name, dest_rel in java_templates.items():
        src_path = templates_dir / src_name
        dest_path = java_base / dest_rel
        shutil.copy(src_path, dest_path)
        replace_placeholders(
            dest_path, {"AUTHOR": AUTHOR, "PROJECT_NAME": project_name}
        )

    # Remove any existing .git directory from the cloned template
    git_dir = project_path / ".git"
    if git_dir.is_dir():
        shutil.rmtree(git_dir)

    # Initialise a fresh git repo, add, commit and create dev branch
    run_cmd("git init -q", cwd=str(project_path))
    run_cmd("git add .", cwd=str(project_path))
    run_cmd('git commit -m "🌱 - Initial commit"', cwd=str(project_path))
    run_cmd("git checkout -b dev", cwd=str(project_path))

    # --- Summary ---------------------------------------------------------
    print("\nProject: " + MAGENTA + project_name + RESET + " created successfully.")
    print("Compiler: " + CYAN + compiler + RESET)
    print("Paper: " + MAGENTA + paperapi_version + RESET)


if __name__ == "__main__":
    main()
