# Headless macOS Server Setup

This project provides a series of scripts to configure a macOS machine (e.g., a Mac mini) as a headless server. This setup is optimized for tasks like running containerized applications (via Colima/Docker) and AI/ML models (via MLX and Ollama).

**Important:**

-   **Run scripts sequentially:** The scripts are numbered and designed to be run in order, starting from `00_initial_setup.sh`.
-   **Sudo Privileges:** Many scripts require `sudo` privileges to modify system settings, install software, or manage services. You will be prompted for your password.
-   **Review Scripts:** It's highly recommended to review the content of each script before execution to understand the changes being made to your system.
-   **User Configuration:** The scripts use environment variables `HEADLESS_SERVER_USER` (defaults to the current user) and `HEADLESS_BASE_DIR` (defaults to `/Users/$HEADLESS_SERVER_USER/headless-mac-server`). These are set in `00_initial_setup.sh` and inherited by subsequent scripts if run in the same session or if exported globally.

## Table of Contents

1.  [Prerequisites](#prerequisites)
2.  [Setup Steps](#setup-steps)
    -   [00_initial_setup.sh](#00_initial_setupsh)
    -   [01_disable_spotlight.sh](#01_disable_spotlightsh)
    -   [02_disable_time_machine.sh](#02_disable_time_machinesh)
    -   [03_configure_power_management.sh](#03_configure_power_managementsh)
    -   [04_disable_screen_saver.sh](#04_disable_screen_saversh)
    -   [05_disable_auto_updates.sh](#05_disable_auto_updatessh)
    -   [06_disable_misc_services.sh](#06_disable_misc_servicessh)
    -   [07_configure_sharing_services.sh](#07_configure_sharing_servicessh)
    -   [08_disable_handoff.sh](#08_disable_handoffsh)
    -   [09_install_homebrew.sh](#09_install_homebrewsh)
    -   [10_install_python_mlx.sh](#10_install_python_mlxsh)
    -   [11_setup_mlx_server_app.sh](#11_setup_mlx_server_appsh)
    -   [12_install_colima_docker.sh](#12_install_colima_dockersh)
    -   [13_create_colima_service.sh](#13_create_colima_servicesh)
    -   [14_create_mlx_api_service.sh](#14_create_mlx_api_servicesh)
    -   [Optional: 15_setup_ollama.sh](#optional-15_setup_ollamash)
3.  [Logging](#logging)
4.  [Contributing](#contributing)
5.  [License](#license)
6.  [Appendix: Understanding macOS Concepts](#appendix-understanding-macos-concepts-for-non-macos-users)

## Prerequisites

-   macOS Monterey (12.0) or later.
-   Administrative (sudo) access to the Mac.
-   Internet connection (for downloading software like Homebrew, Python, Docker, etc.).
-   Familiarity with the command line.

## Setup Steps

Navigate to the `scripts` directory in your terminal before running these scripts. For example:

```bash
git clone https://github.com/quanhua92/headless-mac-server
cd headless-mac-server/scripts
```

Then, execute each script:

```bash
bash ./00_initial_setup.sh
bash ./01_disable_spotlight.sh
# ... and so on for all scripts.
```

---

### `00_initial_setup.sh`

-   **What:** Initializes the setup environment.
-   **Why:** To create a consistent base for all subsequent scripts, including directory structures and logging.
-   **How:**
    -   Defines and exports `HEADLESS_SERVER_USER` (default: current user) and `HEADLESS_BASE_DIR` (default: `/Users/$HEADLESS_SERVER_USER/headless-mac-server`).
    -   Creates the `$HEADLESS_BASE_DIR` and a `$LOG_DIR` (`$HEADLESS_BASE_DIR/logs`) within it.
    -   Sets ownership of these directories to `$HEADLESS_SERVER_USER:staff`.
    -   Makes all `.sh` files within the `scripts`, `scripts/lib`, and `scripts/optional_ollama` directories executable (`chmod +x`).
-   **Inputs:**
    -   Environment variables `HEADLESS_SERVER_USER` and `HEADLESS_BASE_DIR` can be pre-set to override defaults.
-   **Outputs:**
    -   Creates `$HEADLESS_BASE_DIR` and `$HEADLESS_BASE_DIR/logs`.
    -   Initializes `$MAIN_LOG_FILE` (`$LOG_DIR/setup.log`).
    -   Log messages to console and `$MAIN_LOG_FILE`.
-   **Side Effects:**
    -   File permissions changed for `.sh` files in the project.
    -   Directories created on the filesystem.

---

### `01_disable_spotlight.sh`

-   **What:** Disables Spotlight indexing.
-   **Why:** To reduce background CPU and I/O activity, which is often unnecessary for a server and can free up resources.
-   **How:**
    -   Uses `sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.metadata.mds.plist` to disable and unload the main Spotlight daemon (`mds`).
-   **Inputs:** None (uses environment variables set by `00_initial_setup.sh` for logging).
-   **Outputs:**
    -   Log messages to console and `$MAIN_LOG_FILE`.
-   **Side Effects:**
    -   Spotlight search will no longer function effectively.
    -   `mds` and `mdworker` processes will stop consuming resources.
    -   Requires `sudo` privileges.

---

### `02_disable_time_machine.sh`

-   **What:** Disables Time Machine automatic backups.
-   **Why:** To prevent automatic backups that consume resources and disk space, which might be undesirable for a dedicated server with its own backup strategy.
-   **How:**
    -   Checks if Time Machine is configured.
    -   If yes, executes `sudo tmutil disable`.
-   **Inputs:** None.
-   **Outputs:**
    -   Log messages to console and `$MAIN_LOG_FILE`.
-   **Side Effects:**
    -   Automatic Time Machine backups will cease.
    -   Requires `sudo` privileges.

---

### `03_configure_power_management.sh`

-   **What:** Configures power settings for "always-on" operation.
-   **Why:** To ensure the server remains active, responsive, and does not go to sleep or hibernate, which would make it inaccessible.
-   **How:**
    -   Uses `sudo pmset` to:
        -   Set computer sleep to 0 (never): `sudo pmset -a sleep 0`.
        -   Disable hibernation: `sudo pmset -a hibernatemode 0`.
        -   Force disable sleep: `sudo pmset -a disablesleep 1`.
    -   Logs current power settings using `pmset -g`.
-   **Inputs:** None.
-   **Outputs:**
    -   Log messages to console and `$MAIN_LOG_FILE`.
    -   Current power settings are printed and logged.
-   **Side Effects:**
    -   The Mac will consume more power as it will not enter sleep states.
    -   Requires `sudo` privileges.

---

### `04_disable_screen_saver.sh`

-   **What:** Disables the screen saver for the `$HEADLESS_SERVER_USER`.
-   **Why:** Screen savers are unnecessary for a headless server and disabling it saves minimal resources.
-   **How:**
    -   Uses `defaults write com.apple.screensaver idleTime -int 0`.
    -   If the script is not run as `$HEADLESS_SERVER_USER`, it attempts to use `sudo -u "$HEADLESS_SERVER_USER" defaults write ...`.
-   **Inputs:**
    -   Relies on `HEADLESS_SERVER_USER` environment variable.
-   **Outputs:**
    -   Log messages to console and `$MAIN_LOG_FILE`.
-   **Side Effects:**
    -   The screen saver will not activate for the specified user.
    -   May require `sudo` privileges if not run as the target user.

---

### `05_disable_auto_updates.sh`

-   **What:** Disables various automatic software update features in macOS.
-   **Why:** To prevent unexpected system changes, downloads, or reboots. Updates on a server should ideally be managed and applied manually during planned maintenance windows.
-   **How:**
    -   Uses `sudo defaults write` to modify settings in:
        -   `/Library/Preferences/com.apple.SoftwareUpdate` (disabling `AutomaticCheckEnabled`, `AutomaticDownload`, `ConfigDataInstall`, `CriticalUpdateInstall`).
        -   `/Library/Preferences/com.apple.commerce` (disabling `AutoUpdate` for App Store apps).
-   **Inputs:** None.
-   **Outputs:**
    -   Log messages to console and `$MAIN_LOG_FILE`.
-   **Side Effects:**
    -   The system will no longer automatically check for, download, or install macOS updates or App Store updates. Security updates might also be affected depending on the specific keys modified.
    -   Requires `sudo` privileges.

---

### `06_disable_misc_services.sh`

-   **What:** Disables Power Nap and Sudden Motion Sensor (SMS).
-   **Why:** These features are generally not relevant for an always-on server (Power Nap allows some network activity during sleep, which is disabled anyway) or for desktop hardware like a Mac mini (SMS is for laptops to protect hard drives during falls).
-   **How:**
    -   Uses `sudo pmset -a powernap 0`.
    -   Uses `sudo pmset -a sms 0`.
-   **Inputs:** None.
-   **Outputs:**
    -   Log messages to console and `$MAIN_LOG_FILE`.
-   **Side Effects:**
    -   Power Nap and Sudden Motion Sensor features are turned off.
    -   Requires `sudo` privileges.

---

### `07_configure_sharing_services.sh`

-   **What:** Disables File Sharing (AFP, SMB) and Screen Sharing services.
-   **Why:** To reduce the system's attack surface and resource consumption, especially if SSH is the primary and preferred method of remote access. Screen Sharing is explicitly disabled as a common requirement for truly headless setups.
-   **How:**
    -   For AFP: `sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.AppleFileServer.plist`.
    -   For SMB: `sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.smbd.plist`.
    -   For Screen Sharing: Prompts for user confirmation (`yes/NO`). If confirmed:
        -   `sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.screensharing.plist`.
        -   `sudo defaults write /var/db/launchd.db/com.apple.launchd/overrides.plist com.apple.screensharing -dict Disabled -bool true`.
-   **Inputs:**
    -   User confirmation (`yes` or `NO`) for disabling Screen Sharing.
-   **Outputs:**
    -   Log messages to console and `$MAIN_LOG_FILE`.
-   **Side Effects:**
    -   AFP and SMB file sharing services will be stopped and disabled.
    -   Screen Sharing (VNC) service will be stopped and disabled if confirmed.
    -   **Crucial:** Ensure SSH (Remote Login) is enabled and functional _before_ disabling Screen Sharing if it's your only other remote access method.
    -   Requires `sudo` privileges.

---

### `08_disable_handoff.sh`

-   **What:** Disables the Handoff feature for the `$HEADLESS_SERVER_USER`.
-   **Why:** Handoff (continuity between Apple devices) is irrelevant for a headless server and disabling it might free up minor system resources or prevent unwanted network activity.
-   **How:**
    -   Modifies user preferences using `defaults write com.apple.coreservices.useractivityd ActivityAdvertisingAllowed -bool false` and `ActivityReceivingAllowed -bool false`.
    -   Targets the user specified by `HEADLESS_SERVER_USER`, using `sudo -u` if necessary.
-   **Inputs:**
    -   Relies on `HEADLESS_SERVER_USER` environment variable.
-   **Outputs:**
    -   Log messages to console and `$MAIN_LOG_FILE`.
-   **Side Effects:**
    -   Handoff capabilities for the specified user will be disabled.
    -   May require `sudo` privileges if not run as the target user.
    -   A reboot or re-login might be needed for changes to fully apply.

---

### `09_install_homebrew.sh`

-   **What:** Installs Homebrew, the package manager for macOS.
-   **Why:** Homebrew is essential for easily installing many command-line tools and software packages that are not included with macOS, such as Python, Colima, and Docker.
-   **How:**
    -   Checks if `brew` command is already available.
    -   If not, prompts the user for confirmation (`yes/NO`) to proceed.
    -   If confirmed, downloads and executes the official Homebrew installation script from `https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh`.
    -   Attempts to add Homebrew's binary directory (`/opt/homebrew/bin` for Apple Silicon, `/usr/local/bin` for Intel) to the current session's `PATH` and provides instructions for adding it to the shell profile (e.g., `~/.zshrc`).
-   **Inputs:**
    -   User confirmation (`yes` or `NO`) for installing Homebrew.
-   **Outputs:**
    -   Log messages to console and `$MAIN_LOG_FILE`.
    -   Homebrew installation output.
    -   Instructions for updating `PATH` permanently.
-   **Side Effects:**
    -   Homebrew and its dependencies are installed on the system. This process may download a significant amount of data and take some time.
    -   The script will modify `PATH` for the current session if Homebrew is installed.
    -   The Homebrew installer might ask for `sudo` password.
    -   If the user skips installation and Homebrew is required by later scripts, those scripts may fail.

---

### `10_install_python_mlx.sh`

-   **What:** Installs Python 3 (via Homebrew if not already present) and Apple's MLX libraries (`mlx`, `mlx-lm`).
-   **Why:** To set up the necessary Python environment for running machine learning models using MLX, which is optimized for Apple Silicon.
-   **How:**
    -   Ensures `brew` is available and in `PATH`.
    -   Installs Python 3 using `brew install python` if not already installed.
    -   Uses `pip3 install mlx mlx-lm --prefer-binary` to install the MLX libraries.
    -   Verifies the installation by attempting to import MLX packages in Python.
-   **Inputs:** None (assumes Homebrew is installed or will be by script `09`).
-   **Outputs:**
    -   Log messages to console and `$MAIN_LOG_FILE`.
    -   Installation progress from `brew` and `pip3`.
    -   Python version and MLX import verification status.
-   **Side Effects:**
    -   Python 3 and MLX Python packages will be installed or updated.
    -   Requires Homebrew.

---

### `11_setup_mlx_server_app.sh`

-   **What:** Sets up the `mlx-server` from the `mlx-community` project.
-   **Why:** To provide an API endpoint for serving LLM inferences using MLX, with features like model unloading on idle to manage resources.
-   **How:**
    -   Ensures necessary directories exist (`$LIB_DIR`, `$CONFIG_TEMPLATE_DIR`, `$MLX_MODELS_DIR`).
    -   Installs `mlx-server` using `pip3 install mlx-server --prefer-binary`.
    -   Creates an example configuration file (`$CONFIG_TEMPLATE_DIR/mlx_server_config_example.yaml`) with placeholders for models and server settings (like `unload_idle_seconds`).
    -   Creates a helper shell script (`$LIB_DIR/start_mlx_server.sh`) that the `launchd` service will use to start `mlx-server` with the specified configuration. This script handles locating the `mlx-server` executable and logging.
-   **Inputs:**
    -   Uses `HEADLESS_SERVER_USER` and `HEADLESS_BASE_DIR`.
-   **Outputs:**
    -   Log messages to console and `$MAIN_LOG_FILE`.
    -   `mlx-server` installation output.
    -   Creates `$CONFIG_TEMPLATE_DIR/mlx_server_config_example.yaml`.
    -   Creates `$LIB_DIR/start_mlx_server.sh`.
-   **Side Effects:**
    -   `mlx-server` Python package installed.
    -   New directories and files created.
    -   Users need to customize `mlx_server_config_example.yaml` (or a copy) and potentially update the path in `start_mlx_server.sh`.

---

### `12_install_colima_docker.sh`

-   **What:** Installs Colima and the Docker Command Line Interface (CLI).
-   **Why:** Colima provides a container runtime on macOS, acting as a lightweight alternative to Docker Desktop, especially suitable for headless environments. The Docker CLI is needed to interact with Colima and manage Docker containers.
-   **How:**
    -   Ensures `brew` is available and in `PATH`.
    -   Installs Colima using `brew install colima`.
    -   Installs Docker CLI using `brew install docker`.
    -   Logs version information for both tools.
-   **Inputs:** None (assumes Homebrew is installed or will be by script `09`).
-   **Outputs:**
    -   Log messages to console and `$MAIN_LOG_FILE`.
    -   Installation progress from `brew`.
    -   Colima and Docker version information.
-   **Side Effects:**
    -   Colima and Docker CLI (and their dependencies) are installed system-wide via Homebrew.

---

### `13_create_colima_service.sh`

-   **What:** Creates and enables a `launchd` service to automatically start Colima on system boot.
-   **Why:** To ensure the Docker environment (provided by Colima) is available without manual intervention after the server reboots, making containerized applications accessible.
-   **How:**
    -   Ensures the helper script `$LIB_DIR/start_colima.sh` exists, is executable, and owned by `$HEADLESS_SERVER_USER`.
    -   Defines Colima VM settings (profile name, CPU, memory, disk, VM type, mount type) using environment variables with defaults. These are embedded in the `.plist`.
    -   Generates a `.plist` file (`com.headlessmac.colima.daemon.plist`) that configures `launchd` to run `$LIB_DIR/start_colima.sh` as `$HEADLESS_SERVER_USER`. The `.plist` includes environment variables for Colima's configuration.
    -   The `start_colima.sh` script (located in `scripts/lib/`) handles:
        -   Locating the `colima` executable.
        -   Checking if the specified Colima profile is running, stopped, or non-existent.
        -   Starting or creating the Colima profile with the defined parameters.
        -   Waiting for the Docker daemon within Colima to become responsive.
        -   Logging its actions to `$LOG_DIR/colima_daemon.log` and `.err`.
    -   The generated `.plist` is copied to `/Library/LaunchDaemons/`.
    -   Ownership (`root:wheel`) and permissions (`644`) are set for the `.plist` file.
    -   The service is loaded and enabled using `sudo launchctl load -w $TARGET_PLIST_PATH`.
-   **Inputs:**
    -   Uses `HEADLESS_SERVER_USER`, `HEADLESS_BASE_DIR`.
    -   Environment variables for Colima settings (e.g., `COLIMA_PROFILE_NAME`, `COLIMA_CPU`, `COLIMA_MEM`) can be pre-set to override defaults.
    -   Depends on `$LIB_DIR/start_colima.sh` being present and functional.
-   **Outputs:**
    -   Log messages to console and `$MAIN_LOG_FILE`.
    -   Creates `/Library/LaunchDaemons/com.headlessmac.colima.daemon.plist`.
    -   Daemon-specific logs: `$LOG_DIR/colima_launchd.out.log`, `$LOG_DIR/colima_launchd.err.log`.
    -   `start_colima.sh` logs: `$LOG_DIR/colima_daemon.log`, `$LOG_DIR/colima_daemon.err`.
-   **Side Effects:**
    -   A new `launchd` service is created and started.
    -   Colima will attempt to start a VM on boot and when the service is loaded. This will consume system resources (CPU, RAM, disk).
    -   Requires `sudo` privileges.

---

### `14_create_mlx_api_service.sh`

-   **What:** Creates and enables a `launchd` service to automatically start the MLX API server (configured in script `11`) on system boot.
-   **Why:** To provide a persistent LLM API endpoint that is available after reboots, managed by `launchd` for reliability.
-   **How:**
    -   Ensures the helper script `$LIB_DIR/start_mlx_server.sh` (created by script `11`) exists and is executable.
    -   Generates a `.plist` file (`com.headlessmac.mlx.api.service.plist`) for `launchd`. This file configures the service to run `$LIB_DIR/start_mlx_server.sh` as `$HEADLESS_SERVER_USER`.
    -   The `.plist` includes necessary environment variables (e.g., `HOME`, `PATH`, `HEADLESS_SERVER_USER`, `HEADLESS_BASE_DIR`).
    -   The generated `.plist` is copied to `/Library/LaunchDaemons/`.
    -   Ownership (`root:wheel`) and permissions (`644`) are set for the `.plist` file.
    -   The service is loaded and enabled using `sudo launchctl load -w $TARGET_PLIST_PATH_MLX`.
-   **Inputs:**
    -   Uses `HEADLESS_SERVER_USER`, `HEADLESS_BASE_DIR`.
    -   Depends on `$LIB_DIR/start_mlx_server.sh` being present and functional, and `mlx-server` being correctly configured (via its YAML file).
-   **Outputs:**
    -   Log messages to console and `$MAIN_LOG_FILE`.
    -   Creates `/Library/LaunchDaemons/com.headlessmac.mlx.api.service.plist`.
    -   Daemon-specific logs: `$LOG_DIR/mlx_launchd.out.log`, `$LOG_DIR/mlx_launchd.err.log`.
    -   `start_mlx_server.sh` logs: `$LOG_DIR/mlx_server.log`, `$LOG_DIR/mlx_server.err`.
-   **Side Effects:**
    -   A new `launchd` service is created and started.
    -   The MLX API server will attempt to start on boot and when the service is loaded. This will consume CPU, GPU (if applicable for MLX), and RAM, especially when models are loaded.
    -   Requires `sudo` privileges.

---

### `optional_ollama/15_setup_ollama.sh`

-   **What:** (Optional) Sets up Ollama as a `launchd` service.
-   **Why:** To provide another persistent AI model serving option that starts on boot, allowing access to various LLMs through the Ollama API.
-   **How:**
    -   Checks if Ollama is installed. If not, instructs the user to install it and exits.
    -   Ensures the helper script `optional_ollama/lib/start_ollama.sh` exists and is executable.
    -   Defines Ollama environment variables for the service (e.g., `OLLAMA_HOST`, `OLLAMA_MODELS_DIR`, `OLLAMA_KEEP_ALIVE`).
    -   Creates the Ollama models directory (`$OLLAMA_MODELS_DIR`) if it doesn't exist, as `$HEADLESS_SERVER_USER`.
    -   Generates a `.plist` file (`com.headlessmac.ollama.service.plist`) for `launchd`. This file configures the service to run `optional_ollama/lib/start_ollama.sh` as `$HEADLESS_SERVER_USER`.
    -   The `start_ollama.sh` script (located in `scripts/optional_ollama/lib/`) handles:
        -   Locating the `ollama` executable.
        -   Executing `ollama serve`. Ollama handles its own detailed logging.
        -   Logging its own startup messages to `$LOG_DIR/ollama_daemon.log` and `.err`.
    -   The generated `.plist` is copied to `/Library/LaunchDaemons/`.
    -   Ownership (`root:wheel`) and permissions (`644`) are set for the `.plist` file.
    -   The service is loaded and enabled using `sudo launchctl load -w $TARGET_PLIST_PATH_OLLAMA`.
-   **Inputs:**
    -   Uses `HEADLESS_SERVER_USER`, `HEADLESS_BASE_DIR`.
    -   Environment variables for Ollama settings (e.g., `OLLAMA_HOST`, `OLLAMA_MODELS_DIR`) can be pre-set.
    -   Requires Ollama to be pre-installed by the user.
    -   Depends on `optional_ollama/lib/start_ollama.sh` being present.
-   **Outputs:**
    -   Log messages to console and `$MAIN_LOG_FILE`.
    -   Creates `/Library/LaunchDaemons/com.headlessmac.ollama.service.plist`.
    -   Daemon-specific logs (launchd wrapper): `$LOG_DIR/ollama_launchd.out.log`, `$LOG_DIR/ollama_launchd.err.log`.
    -   `start_ollama.sh` script logs: `$LOG_DIR/ollama_daemon.log`, `$LOG_DIR/ollama_daemon.err`.
    -   Ollama itself will generate logs in its standard location (often `~/.ollama/logs`).
-   **Side Effects:**
    -   A new `launchd` service for Ollama is created and started.
    -   Ollama will run on boot, consuming resources based on its configuration and loaded models.
    -   Requires `sudo` privileges.

---

## Logging

-   **Main Setup Log:** All scripts append their primary actions to `$HEADLESS_BASE_DIR/logs/setup.log`.
-   **Service-Specific Logs:**
    -   LaunchDaemon stdout/stderr (for initial launch messages):
        -   Colima: `$HEADLESS_BASE_DIR/logs/colima_launchd.out.log`, `colima_launchd.err.log`
        -   MLX API: `$HEADLESS_BASE_DIR/logs/mlx_launchd.out.log`, `mlx_launchd.err.log`
        -   Ollama: `$HEADLESS_BASE_DIR/logs/ollama_launchd.out.log`, `ollama_launchd.err.log`
    -   Helper Script Logs (more detailed operational logs from the scripts run by `launchd`):
        -   Colima (`start_colima.sh`): `$HEADLESS_BASE_DIR/logs/colima_daemon.log`, `colima_daemon.err`
        -   MLX API (`start_mlx_server.sh`): `$HEADLESS_BASE_DIR/logs/mlx_server.log`, `mlx_server.err`
        -   Ollama (`start_ollama.sh`): `$HEADLESS_BASE_DIR/logs/ollama_daemon.log`, `ollama_daemon.err`
-   **Ollama Native Logs:** Check `~/.ollama/logs` (for the `$HEADLESS_SERVER_USER`) for detailed Ollama server logs.

Check these log files for troubleshooting if any step fails or services do not behave as expected.

## Contributing

Contributions are welcome! If you'd like to contribute, please follow these guidelines:

1.  Fork the repository.
2.  Create a new branch: `git checkout -b feature/your-feature-name` or `bugfix/your-bug-fix`.
3.  Make your changes and commit them: `git commit -m 'Add some feature'`.
4.  Push to the branch: `git push origin feature/your-feature-name`.
5.  Open a Pull Request.

Please make sure to update tests as appropriate.

## License

This project is licensed under the MIT License. (You would typically have a `LICENSE` file in your repository).

---

## Appendix: Understanding macOS Concepts for Non-macOS Users

This section aims to clarify some macOS-specific terminology and concepts that are relevant to this project, especially for users coming from Windows or Linux backgrounds.

### 1. Services: Daemons and Agents

On macOS, background processes that run without direct user interaction are generally referred to as services. These are managed by a system called `launchd`. There are two main types:

-   **Daemons:** These are system-wide services that run in the background, typically starting when the system boots up and running independently of any logged-in user. They often perform tasks for the entire system.
    -   _Analogous to:_ System services in Windows or daemons/services managed by `systemd` or `init` in Linux (e.g., `httpd`, `sshd`).
-   **Agents (Launch Agents):** These are services that run on behalf of a logged-in user. They typically start when a user logs in and stop when the user logs out. They can access user-specific settings and data.
    -   _Analogous to:_ User-specific scheduled tasks or startup applications in Windows, or user-level systemd services in Linux.

### 2. `launchd`: The Service Management Framework

`launchd` is the core service management framework in macOS. It's responsible for starting, stopping, and managing daemons and agents. It replaces older systems like `init`, `rc`, and `cron` (though `cron` can still be used, `launchd` is preferred for new services).

-   **Key Responsibilities of `launchd`:**
    -   Launching processes on demand (e.g., when a network connection is made to a specific port).
    -   Launching processes at scheduled intervals (like `cron`).
    -   Launching processes when files or directories change.
    -   Keeping processes running (restarting them if they crash).
-   _Analogous to:_ `systemd` on modern Linux distributions, or the Service Control Manager (SCM) in Windows.

### 3. Property List Files (`.plist`)

Services managed by `launchd` are configured using special XML files called Property List files, or `.plist` files. These files define how a service should be run.

-   **Structure:** `.plist` files are typically XML-based (though they can also be binary) and contain key-value pairs.
-   **Purpose for Services:** For a `launchd` service, the `.plist` file specifies:
    -   `Label`: A unique identifier for the service (e.g., `com.example.myservice`).
    -   `ProgramArguments`: The command and arguments to execute.
    -   `UserName`: The user account under which the service should run.
    -   `RunAtLoad`: Whether to start the service immediately when it's loaded by `launchd`.
    -   `KeepAlive`: Conditions under which `launchd` should keep the service running or restart it if it exits (e.g., `SuccessfulExit: false`, `Crashed: true` means restart if it crashes or exits with non-zero status).
    -   `StandardOutPath` / `StandardErrorPath`: Files to redirect the service's standard output and standard error streams.
    -   `EnvironmentVariables`: A dictionary of environment variables to set for the service.
    -   And many other parameters like working directory, start interval, etc.
-   **Common Locations for Service `.plist` Files:**
    -   `/System/Library/LaunchDaemons/`: For daemons provided by Apple as part of macOS. (Generally, do not modify these).
    -   `/Library/LaunchDaemons/`: For system-wide daemons installed by third-party software or administrators (This is where this project places its service files).
    -   `/System/Library/LaunchAgents/`: For agents provided by Apple. (Generally, do not modify these).
    -   `/Library/LaunchAgents/`: For agents installed by third-party software or administrators, intended to run for any logged-in user.
    -   `~/Library/LaunchAgents/`: (where `~` is the user's home directory) For agents specific to a particular user.
-   _Analogous to:_ `.service` unit files for `systemd` in Linux, or registry entries and service configuration details in Windows.

### 4. Managing Services with `launchctl`

`launchctl` is the command-line utility used to interact with `launchd`. It allows you to load, unload, start, stop, and manage services. You typically need administrative (`sudo`) privileges to manage daemons or agents in system-level directories like `/Library/LaunchDaemons/`.

-   **Common `launchctl` Commands Used in This Project:**

    -   `sudo launchctl load -w <path_to_plist_file>`: Loads the service definition from the specified `.plist` file into `launchd` and starts it if `RunAtLoad` is true. The `-w` flag makes the service enabled persistently across reboots (it effectively removes a "disabled" override if one exists). This is the primary command used by the scripts to install and enable the services.
    -   `sudo launchctl unload [-w] <path_to_plist_file>`: Stops the service (if running) and unloads its definition from `launchd`. If `-w` is used, it also marks the service as disabled persistently. This project uses `unload` (without `-w` sometimes, just to stop it before reloading) when updating a service definition.
    -   `sudo launchctl list | grep <service_label>`: (Not directly in scripts but useful for users) Lists services currently loaded by `launchd` and filters for a specific service label (e.g., `com.headlessmac.colima.daemon`).
    -   `sudo launchctl enable <service_target>`: (More modern approach) Marks a service to be loaded automatically. Example: `sudo launchctl enable system/com.openssh.sshd`.
    -   `sudo launchctl disable <service_target>`: (More modern approach) Prevents a service from being loaded automatically.
    -   Service Target format: e.g., `system/<label>` for system daemons, `user/<uid>/<label>` for user agents for a specific user ID.

-   **Enabling/Disabling Services:**
    -   This project primarily uses `sudo launchctl load -w <path_to_plist>` to enable services. This command effectively tells `launchd` to read the `.plist` file and ensure the service is set to run (now and on subsequent boots/logins as configured).
    -   "Disabling" a service in these scripts (like Spotlight or File Sharing) typically involves `sudo launchctl unload -w <path_to_system_plist>`, which stops it and prevents it from starting automatically.

### 5. SSH (Secure Shell) on macOS

SSH is a protocol for secure remote login and other secure network services over an insecure network.

-   **SSH Server (Remote Login):**
    -   macOS comes with a built-in SSH server (OpenSSH's `sshd`). When enabled, it allows users to log into the Mac remotely from other computers using an SSH client.
    -   **This project assumes SSH is already enabled on your Mac for remote access.** If not, you can enable it via `System Settings` > `General` > `Sharing` > toggle `Remote Login` on.
    -   The service responsible is `com.openssh.sshd`, and its `.plist` is typically `/System/Library/LaunchDaemons/ssh.plist`.
-   **SSH Client:**
    -   macOS also includes an SSH client, accessible via the `ssh` command in the Terminal (e.g., `Terminal.app` or `iTerm2`). You use this to connect to other servers.

By understanding these concepts, non-macOS users should find it easier to follow the project's setup, configuration, and operational details.
