#!/bin/bash

# English messages for Tarsync
# Tarsync 영어 메시지

# Language metadata
LANG_CODE="en"
LANG_NAME="English"
LANG_LOCALE="en_US.UTF-8"
LANG_TIMEZONE="UTC"
LANG_DIRECTION="ltr"
LANG_VERSION="1.0"

# ======================
# CLI Interface Messages
# ======================

# Help system
MSG_HELP_USAGE="Usage: tarsync <command> [arguments]"
MSG_HELP_DESCRIPTION="Shell Script-based reliable backup and restore tool"
MSG_HELP_COMMANDS="Main Commands:"
MSG_HELP_BACKUP="backup [path]           # Backup specific path or entire system (default: /)"
MSG_HELP_RESTORE="restore [backup] [target] # Restore selected backup to specified path"
MSG_HELP_LIST="list                    # Display created backup list in latest order"
MSG_HELP_LOG="log <number|name>        # Display backup notes and logs"
MSG_HELP_DELETE="delete <name>           # Permanently delete specified backup"
MSG_HELP_DETAILS="details <name>          # Display detailed backup information"
MSG_HELP_OTHER_COMMANDS="Other Commands:"
MSG_HELP_VERSION="version                 # Display program version information"
MSG_HELP_HELP="help                    # Display this help"
MSG_HELP_EXAMPLES="Usage Examples:"
MSG_HELP_EXAMPLE_BACKUP="sudo %s backup /home/user    # Backup /home/user directory"
MSG_HELP_EXAMPLE_RESTORE="sudo %s restore              # Start interactive restore mode"
MSG_HELP_EXAMPLE_RESTORE_TARGET="sudo %s restore 1 /tmp/res   # Restore backup #1 to /tmp/res"
MSG_HELP_EXAMPLE_LIST="%s list                      # View backup list"
MSG_HELP_EXAMPLE_LOG="%s log 7                     # View notes and logs for backup #7"
MSG_HELP_EXAMPLE_DELETE="sudo %s delete backup_name   # Delete specific backup"

# Error messages
MSG_ERROR_SUDO_REQUIRED="❌ System backup/restore requires sudo privileges"
MSG_ERROR_SUDO_HINT="💡 Please run as follows: %ssudo %s %s%s"
MSG_ERROR_SUDO_REASON="📖 Privileges required for:"
MSG_ERROR_SUDO_REASON_FILES="  • Reading system files (/etc, /var, /root, etc.)"
MSG_ERROR_SUDO_REASON_BACKUP="  • Creating backup files"
MSG_ERROR_SUDO_REASON_RESTORE="  • Restoring original permissions"
MSG_ERROR_INVALID_COMMAND="Invalid command: %s"
MSG_ERROR_MISSING_ARGUMENT="Missing required argument: %s"
MSG_ERROR_INVALID_PATH="Invalid path: %s"
MSG_ERROR_PERMISSION_DENIED="Permission denied: %s"

# Version messages
MSG_VERSION_HEADER="%s v%s"
MSG_VERSION_DESCRIPTION="Shell Script-based backup tool"
MSG_VERSION_FEATURES="📦 Features:"
MSG_VERSION_FEATURE_BACKUP="  • tar+gzip compressed backup"
MSG_VERSION_FEATURE_RESTORE="  • rsync-based restore"
MSG_VERSION_FEATURE_LIST="  • Paginated list management"
MSG_VERSION_FEATURE_INTEGRITY="  • Backup integrity checking"
MSG_VERSION_FEATURE_LOG="  • Log management"
MSG_VERSION_DEPENDENCIES="🛠️  Dependencies:"
MSG_VERSION_DEPS_LIST="  • tar, gzip, rsync, pv, bc, jq"
MSG_VERSION_COPYRIGHT="Copyright (c) %s"

# ======================
# Backup Module Messages
# ======================

# Backup status
MSG_BACKUP_START="Starting backup process..."
MSG_BACKUP_PROGRESS="Progress: %s%% - %s"
MSG_BACKUP_COMPLETE="✅ Backup completed successfully"
MSG_BACKUP_FAILED="❌ Backup failed: %s"
MSG_BACKUP_CREATING_ARCHIVE="Creating compressed archive..."
MSG_BACKUP_CALCULATING_SIZE="Calculating backup size..."
MSG_BACKUP_PREPARING="Preparing backup..."
MSG_BACKUP_FINALIZING="Finalizing backup..."

# User notes editing
MSG_NOTES_EDIT="📝 Editing user notes..."
MSG_NOTES_EDIT_INFO="   (Write your desired notes in the empty file)"
MSG_NOTES_EDITOR_VIM="   (Save and exit: :wq, Exit without saving: :q)"
MSG_NOTES_EDITOR_NANO="   (Save and exit: Ctrl+X)"
MSG_NOTES_NO_EDITOR="⚠️  Text editor not found. Creating basic log only."
MSG_NOTES_SAVED="📝 User notes saved successfully."

# Backup creation
MSG_BACKUP_CREATING_DIR="Creating backup directory: %s"
MSG_BACKUP_CREATING_META="Creating backup metadata..."
MSG_BACKUP_CREATING_LOG="Creating backup log..."
MSG_BACKUP_DISK_SPACE_CHECK="Checking available disk space..."
MSG_BACKUP_EXCLUDE_PATHS="Excluding %d paths from backup"

# ======================
# Restore Module Messages  
# ======================

# Restore selection
MSG_RESTORE_SELECT="Select backup to restore:"
MSG_RESTORE_CONFIRM="Are you sure you want to restore %s to %s? (y/N)"
MSG_RESTORE_COMPLETE="✅ Restore completed successfully"
MSG_RESTORE_FAILED="❌ Restore failed: %s"
MSG_RESTORE_CANCELLED="Restore cancelled"

# Restore modes
MSG_RESTORE_MODE_SELECT="Select restore mode:"
MSG_RESTORE_MODE_SAFE="Safe mode (preserve existing files)"
MSG_RESTORE_MODE_FULL="Full mode (overwrite existing files)"
MSG_RESTORE_PREPARING="Preparing restore operation..."
MSG_RESTORE_EXTRACTING="Extracting backup archive..."
MSG_RESTORE_COPYING="Copying files to destination..."
MSG_RESTORE_SETTING_PERMISSIONS="Setting file permissions..."

# ======================
# List Management Messages
# ======================

# Backup list
MSG_LIST_HEADER="Available backups (showing %d of %d):"
MSG_LIST_NO_BACKUPS="No backups found"
MSG_LIST_PAGE_INFO="Page %d of %d (Press Enter for next page, 'q' to quit)"
MSG_LIST_LOADING="Loading backup list..."
MSG_LIST_COLUMN_NO="NO"
MSG_LIST_COLUMN_NAME="NAME"
MSG_LIST_COLUMN_SIZE="SIZE"
MSG_LIST_COLUMN_DATE="DATE"
MSG_LIST_COLUMN_SOURCE="SOURCE"

# Backup details
MSG_DETAILS_SIZE="Size: %s"
MSG_DETAILS_DATE="Created: %s"
MSG_DETAILS_SOURCE="Source: %s"
MSG_DETAILS_DESTINATION="Destination: %s"
MSG_DETAILS_DURATION="Duration: %s"
MSG_DETAILS_STATUS="Status: %s"
MSG_DETAILS_EXCLUDE_COUNT="Excluded paths: %d"
MSG_DETAILS_NOTES="Notes: %s"

# Log display
MSG_LOG_HEADER="=== Backup Log: %s ==="
MSG_LOG_NOTES_HEADER="📝 User Notes:"
MSG_LOG_DETAILS_HEADER="📊 Backup Details:"
MSG_LOG_NO_NOTES="No user notes available"
MSG_LOG_NO_LOG_FILE="Log file not found"

# ======================
# System Messages
# ======================

# Permission management
MSG_SYSTEM_SUDO_REQUIRED="Administrative privileges required"
MSG_SYSTEM_PERMISSION_DENIED="Permission denied: %s"
MSG_SYSTEM_CHECKING_PERMISSIONS="Checking permissions..."

# File system
MSG_SYSTEM_CREATING_DIR="Creating directory: %s"
MSG_SYSTEM_FILE_NOT_FOUND="File not found: %s"
MSG_SYSTEM_DISK_SPACE="Available space: %s"
MSG_SYSTEM_DIRECTORY_EXISTS="Directory already exists: %s"
MSG_SYSTEM_COPYING_FILE="Copying file: %s"
MSG_SYSTEM_REMOVING_FILE="Removing file: %s"

# Process management
MSG_SYSTEM_STARTING_PROCESS="Starting process: %s"
MSG_SYSTEM_PROCESS_COMPLETE="Process completed: %s"
MSG_SYSTEM_PROCESS_FAILED="Process failed: %s"

# ======================
# Installation Messages
# ======================

# Installation process  
MSG_INSTALL_START="Starting tarsync installation..."
MSG_INSTALL_COMPLETE="✅ Installation completed successfully"
MSG_INSTALL_FAILED="❌ Installation failed: %s"
MSG_INSTALL_ALREADY_INSTALLED="Tarsync is already installed"

# Dependency check
MSG_INSTALL_CHECKING_DEPS="Checking required dependencies..."
MSG_INSTALL_DEPS_OK="✅ All dependencies are satisfied"
MSG_INSTALL_DEPS_MISSING="⚠️  Missing required tools: %s"
MSG_INSTALL_DEPS_INSTALL_CMD="Install command: %s"

# Automatic installation
MSG_INSTALL_AUTO_DEPS="Installing dependencies automatically..."
MSG_INSTALL_AUTO_SUCCESS="✅ Dependencies installed successfully"
MSG_INSTALL_AUTO_FAILED="❌ Automatic installation failed"
MSG_INSTALL_MANUAL_GUIDE="📋 Manual installation guide:"

# File operations
MSG_INSTALL_COPYING_FILES="Copying program files..."
MSG_INSTALL_SETTING_PERMISSIONS="Setting file permissions..."
MSG_INSTALL_CREATING_SYMLINK="Creating symbolic link..."
MSG_INSTALL_CONFIGURING_SYSTEM="Configuring system settings..."

# Language setup
MSG_INSTALL_LANGUAGE_SETUP="Setting up language configuration..."
MSG_INSTALL_LANGUAGE_DETECTION="Detecting system language: %s"
MSG_INSTALL_LANGUAGE_CONFIG="Configuring language: %s"
MSG_INSTALL_LANGUAGE_FILES_COPIED="Language files copied successfully"
MSG_INSTALL_FINDING_LANGUAGES="Finding available languages..."
MSG_INSTALL_SELECT_LANGUAGE="📍 Please select installation language"
MSG_INSTALL_CANCEL="Cancel installation"
MSG_INSTALL_LANGUAGE_SELECTED="✓ Selected language: %s (%s)"
MSG_INSTALL_LANGUAGE_INVALID="⚠️  Invalid input. Setting to default language: %s (%s)"
MSG_INSTALL_LANGUAGE_CONFIGURED="📝 Language configuration completed"

# Installation stages
MSG_INSTALL_INITIALIZING="Initializing installation..."
MSG_INSTALL_CHECKING_EXISTING="Checking existing installation..."
MSG_INSTALL_ALL_DEPS_OK="All dependencies are satisfied"
MSG_INSTALL_CONFIRM_PROCEED="Do you want to continue with installation? (Y/n)"
MSG_INSTALL_CANCELLED="Installation cancelled"
MSG_INSTALL_STARTING="Starting tarsync installation..."
MSG_INSTALL_FILES="Installing files..."

# Backup directory setup
MSG_INSTALL_BACKUP_SETUP="📁 Setting up backup storage location"
MSG_INSTALL_BACKUP_PROMPT="Please enter the directory where backup files will be stored:"
MSG_INSTALL_BACKUP_DEFAULT="• Default: %s"
MSG_INSTALL_BACKUP_EXAMPLES="• Examples: ~/backup/tarsync, /data/backup/tarsync, /var/backup/tarsync"
MSG_INSTALL_BACKUP_INPUT="Backup directory [%s]: "
MSG_INSTALL_BACKUP_SELECTED="Selected backup directory: %s"
MSG_INSTALL_BACKUP_CREATED="✅ Backup directory created: %s"
MSG_INSTALL_BACKUP_PERMISSIONS_OK="✅ Backup directory permissions verified"
MSG_INSTALL_BACKUP_SETUP_COMPLETE="📦 Backup directory setup completed"

# File operations  
MSG_INSTALL_FILES_COPIED="Program files copied successfully"
MSG_INSTALL_BACKUP_LOCATION="Backup storage location: %s"
MSG_INSTALL_SCRIPT_INSTALLED="tarsync script installed: %s"
MSG_INSTALL_VERSION_INSTALLED="VERSION file installed: %s"

# Completion system
MSG_INSTALL_COMPLETION_INSTALLING="Installing auto-completion..."
MSG_INSTALL_COMPLETION_INSTALLED="Auto-completion files installed"
MSG_INSTALL_COMPLETION_BASH_SETUP="Setting up bash-completion system..."
MSG_INSTALL_COMPLETION_BASH_INSTALLED="bash-completion package already installed"
MSG_INSTALL_COMPLETION_BASH_ACTIVE="bash completion already activated"
MSG_INSTALL_COMPLETION_BASH_COMPLETE="bash-completion system setup completed"
MSG_INSTALL_COMPLETION_BASH_GLOBAL="Bash auto-completion installed system-wide"
MSG_INSTALL_COMPLETION_ZSH_GLOBAL="ZSH auto-completion installed system-wide"

# Path setup
MSG_INSTALL_PATH_UPDATING="Updating PATH..."
MSG_INSTALL_PATH_NOT_NEEDED="Executable installed in /usr/local/bin, PATH update not required"

# Installation verification
MSG_INSTALL_VERIFYING="Verifying installation..."
MSG_INSTALL_SUCCESS_TITLE="🎉 tarsync v%s installation completed!"
MSG_INSTALL_LOCATIONS="📍 Installation locations:"
MSG_INSTALL_EXECUTABLE="• Executable: %s"
MSG_INSTALL_VERSION_FILE="• Version file: %s"
MSG_INSTALL_LIBRARY="• Library: %s"
MSG_INSTALL_BASH_COMPLETION="• Bash completion: %s"
MSG_INSTALL_ZSH_COMPLETION="• ZSH completion: %s"

# Auto-completion setup
MSG_INSTALL_COMPLETION_IMMEDIATE="🚀 To use auto-completion immediately:"
MSG_INSTALL_CONTAINER_DETECTED="📦 Container environment detected"
MSG_INSTALL_BASH_DETECTED="🐚 Bash environment detected"
MSG_INSTALL_ZSH_DETECTED="🐚 ZSH environment detected"
MSG_INSTALL_COMPLETION_OPTIONS="Choose one of the following:"
MSG_INSTALL_COMPLETION_RELOAD_BASHRC="1) source ~/.bashrc              # Reload configuration file"
MSG_INSTALL_COMPLETION_LOAD_DIRECT="2) source /etc/bash_completion   # Load completion directly"
MSG_INSTALL_COMPLETION_NEW_SESSION="3) exec bash                     # Start new shell session (recommended)"
MSG_INSTALL_COMPLETION_RELOAD_ZSHRC="1) source ~/.zshrc               # Reload configuration file"
MSG_INSTALL_COMPLETION_REINIT_ZSH="2) autoload -U compinit && compinit  # Re-initialize completion"
MSG_INSTALL_COMPLETION_NEW_ZSH="3) exec zsh                      # Start new shell session (recommended)"
MSG_INSTALL_COMPLETION_COPY_TIP="💡 Copy and paste the command into your terminal"

# Usage examples
MSG_INSTALL_USAGE_EXAMPLES="📖 tarsync command usage:"
MSG_INSTALL_USAGE_HELP="      tarsync help                    # Show help"
MSG_INSTALL_USAGE_VERSION="      tarsync version                 # Check version"  
MSG_INSTALL_USAGE_BACKUP="      tarsync backup /home/user       # Backup directory"
MSG_INSTALL_USAGE_LIST="      tarsync list                    # List backups"
MSG_INSTALL_COMPLETION_TIP="💡 Press Tab to use auto-completion!"

# Additional installation messages (from remaining hardcoded strings)
MSG_INSTALL_MANUAL_GUIDE_HEADER="📋 Manual installation guide:"
MSG_INSTALL_DEPS_INSTALLING="Installing dependencies automatically..."
MSG_INSTALL_DEPS_COMMAND="   Execute command: %s"
MSG_INSTALL_DEPS_SUCCESS="✅ Dependencies installed successfully!"
MSG_INSTALL_DEPS_FAILED="❌ Automatic installation failed"
MSG_INSTALL_DEPS_MISSING_TOOLS="⚠️  Following required tools are not installed: %s"
MSG_INSTALL_LINUX_DETECTED="🚀 Linux system detected (%s)"
MSG_INSTALL_MACOS_DETECTED="🍎 macOS system detected"
MSG_INSTALL_HOMEBREW_MISSING="Homebrew is not installed"
MSG_INSTALL_HOMEBREW_INSTALL="Homebrew installation: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
MSG_INSTALL_CONFIRM_AUTO_INSTALL="Install automatically? (Y/n): "
MSG_INSTALL_SOME_TOOLS_MISSING="Some tools are still not installed: %s"
MSG_INSTALL_UNSUPPORTED_SYSTEM="Automatic installation not supported for this system: %s"
MSG_INSTALL_BASH_REQUIRED="Bash shell is required"
MSG_INSTALL_SUDO_REQUIRED="Administrative privileges required for global installation"
MSG_INSTALL_SUDO_HINT="Please run as follows: sudo ./bin/install.sh"
MSG_INSTALL_WRITE_PERMISSION_ERROR="No write permission to system directories"

# Backup directory setup messages
MSG_INSTALL_BACKUP_DIR_NOT_EXIST="Backup directory does not exist. Attempting to create..."
MSG_INSTALL_BACKUP_DIR_CREATED="✅ Backup directory created: %s"
MSG_INSTALL_BACKUP_DIR_CREATE_FAILED="⚠️ Failed to create directory. sudo privileges may be required."
MSG_INSTALL_BACKUP_DIR_COMMAND_TIP="Try running the following commands:"
MSG_INSTALL_BACKUP_DIR_RETRY_PROMPT="Run the above commands and retry installation? (y/N): "
MSG_INSTALL_BACKUP_DIR_SUDO_SUCCESS="✅ Backup directory created using sudo"
MSG_INSTALL_BACKUP_DIR_SUDO_FAILED="❌ Failed to create backup directory"
MSG_INSTALL_BACKUP_DIR_CANNOT_CREATE="❌ Cannot create backup directory, installation aborted"
MSG_INSTALL_BACKUP_DIR_NO_WRITE="⚠️ No write permission to backup directory: %s"
MSG_INSTALL_BACKUP_DIR_FIX_PERMISSION="Attempt to fix permissions?"
MSG_INSTALL_BACKUP_DIR_FIX_COMMAND="   Command to execute: sudo chown \$USER:\$USER '%s'"
MSG_INSTALL_BACKUP_DIR_FIX_PROMPT="Fix permissions? (y/N): "
MSG_INSTALL_BACKUP_DIR_PERMISSION_FIXED="✅ Permissions fixed, backup directory can be used"
MSG_INSTALL_BACKUP_DIR_FIX_FAILED="❌ Permission fix failed"
MSG_INSTALL_BACKUP_DIR_USE_OTHER="Use a different backup directory? (Y/n): "
MSG_INSTALL_BACKUP_DIR_ENTER_NEW="Enter a different backup directory:"
MSG_INSTALL_BACKUP_DIR_INPUT_PROMPT="   Backup directory: "
MSG_INSTALL_BACKUP_DIR_NEW_PATH="New backup directory: %s"
MSG_INSTALL_BACKUP_DIR_NEW_SUCCESS="✅ New backup directory created: %s"
MSG_INSTALL_BACKUP_DIR_NEW_FAILED="❌ Failed to create new backup directory"
MSG_INSTALL_BACKUP_DIR_NEW_NO_WRITE="❌ No write permission to new backup directory: %s"
MSG_INSTALL_BACKUP_DIR_NEW_PERMISSION_OK="✅ New backup directory permissions verified"
MSG_INSTALL_BACKUP_DIR_INVALID="❌ No valid backup directory entered"
MSG_INSTALL_BACKUP_DIR_NO_AVAILABLE="❌ No available backup directory, installation aborted"
MSG_INSTALL_BACKUP_DIR_PERMISSION_ERROR="❌ Backup directory permission error, installation aborted"

# Language selection
MSG_INSTALL_DEFAULT_MARK=" (default)"
MSG_INSTALL_LANGUAGE_INPUT="Select a language (0-%d): "

# Installation verification
MSG_INSTALL_VERIFY_FAILED="tarsync installation failed"
MSG_INSTALL_SCRIPT_NOT_FOUND="tarsync script not found: %s"
MSG_INSTALL_SUCCESS_HEADER="🎉 tarsync v%s installation completed!"
MSG_INSTALL_LOCATIONS_HEADER="📍 Installation locations:"
MSG_INSTALL_LOCATION_EXECUTABLE="   • Executable: %s"
MSG_INSTALL_LOCATION_VERSION="   • Version file: %s"
MSG_INSTALL_LOCATION_LIBRARY="   • Library: %s"
MSG_INSTALL_LOCATION_BASH_COMPLETION="   • Bash completion: %s"
MSG_INSTALL_LOCATION_ZSH_COMPLETION="   • ZSH completion: %s"

# Shell completion messages
MSG_INSTALL_BASH_ENV_DETECTED="🐚 Bash environment detected"
MSG_INSTALL_ZSH_ENV_DETECTED="🐚 ZSH environment detected"
MSG_INSTALL_SHELL_ENV="🐚 Shell environment: %s"
MSG_INSTALL_COMPLETION_CHOOSE_ONE="Choose one of the following:"
MSG_INSTALL_COMPLETION_COPY_COMMAND="💡 Copy and paste the command into your terminal"
MSG_INSTALL_COMPLETION_TITLE="🚀 To use auto-completion immediately:"
MSG_INSTALL_CONTAINER_ENV_DETECTED="📦 Container environment detected"

# bash-completion system
MSG_INSTALL_BASH_COMPLETION_SETUP="Setting up bash-completion system..."
MSG_INSTALL_BASH_COMPLETION_INSTALLING="Installing bash-completion package..."
MSG_INSTALL_BASH_COMPLETION_UNSUPPORTED="Automatic installation not supported for this system: %s"
MSG_INSTALL_BASH_COMPLETION_MANUAL="Please install manually with the following commands:"
MSG_INSTALL_BASH_COMPLETION_SUCCESS="✅ bash-completion package installed"
MSG_INSTALL_BASH_COMPLETION_FAILED="❌ bash-completion package installation failed"
MSG_INSTALL_BASH_COMPLETION_INSTALLED="bash-completion package already installed"
MSG_INSTALL_BASH_COMPLETION_ACTIVE="bash completion already activated"
MSG_INSTALL_BASH_COMPLETION_ACTIVATING="Activating bash completion..."
MSG_INSTALL_BASH_COMPLETION_ACTIVATED="✅ bash completion activated"
MSG_INSTALL_BASH_COMPLETION_ACTIVATE_FAILED="❌ bash completion activation failed"
MSG_INSTALL_BASH_COMPLETION_BASHRC_NOT_FOUND="/etc/bash.bashrc file not found"
MSG_INSTALL_BASH_COMPLETION_SYSTEM_COMPLETE="bash-completion system setup completed"

# Header and final messages
MSG_INSTALL_HEADER_TITLE="TARSYNC INSTALLER"
MSG_INSTALL_HEADER_SUBTITLE="Shell Script Backup System"
MSG_INSTALL_EXISTING_DIR_FOUND="Existing installation directory found: %s"
MSG_INSTALL_CHECKING_DEPS_HEADER="Checking required dependencies..."
MSG_INSTALL_REMOVING_EXISTING="Removing existing installation..."

# Uninstall process
MSG_UNINSTALL_START="Starting tarsync removal..."
MSG_UNINSTALL_CONFIRM="Are you sure you want to remove tarsync? (y/N)"
MSG_UNINSTALL_CANCELLED="Removal cancelled"
MSG_UNINSTALL_COMPLETE="✅ Tarsync removed successfully"
MSG_UNINSTALL_BACKUP_PRESERVED="Backup data preserved at: %s"

# ======================
# Generic Messages
# ======================

MSG_YES="y"
MSG_NO="n"
MSG_CONTINUE="Continue"
MSG_CANCEL="Cancel"
MSG_LOADING="Loading..."
MSG_PLEASE_WAIT="Please wait..."
MSG_DONE="Done"
MSG_SUCCESS="Success"
MSG_FAILED="Failed"
MSG_WARNING="Warning"
MSG_ERROR="Error"
MSG_INFO="Info"

# ======================
# Configuration Messages
# ======================

MSG_HELP_CONFIG="config [lang|reset|help]    Manage user settings"
MSG_HELP_EXAMPLE_CONFIG="  %s config lang en       # Set language to English"
MSG_CONFIG_RESTART_HINT="💡 Changes will take effect in new %s sessions"

# ======================
# Restore Module Messages
# ======================

MSG_RESTORE_SELECT_BACKUP="Select backup to restore (number or directory name): "
MSG_RESTORE_BACKUP_NOT_FOUND="❌ Backup number %s not found"
MSG_RESTORE_INVALID_BACKUP="❌ Selected backup is invalid or missing required files: %s"
MSG_RESTORE_INVALID_TARGET="❌ Target path is invalid or no write permission: %s"
MSG_RESTORE_MODE_SELECT="⚙️  Select restore mode"
MSG_RESTORE_BACKUP_INFO="  - 📦 Backup: %s"
MSG_RESTORE_MODE_SAFE="1️⃣  Safe restore (default)"
MSG_RESTORE_MODE_SAFE_DESC="    Keep existing files intact, only add or overwrite with backup content."
MSG_RESTORE_MODE_SAFE_RECOMMEND="    (Recommended for general restore.)"
MSG_RESTORE_MODE_FULL="2️⃣  Full synchronization (⚠️ Warning: file deletion)"
MSG_RESTORE_MODE_FULL_DESC="    Make it identical to backup state."
MSG_RESTORE_MODE_CANCEL="3️⃣  Cancel restore"
MSG_RESTORE_MODE_CANCEL_DESC="    Cancel restore operation."
MSG_RESTORE_INVALID_CHOICE="❌ Invalid choice. Please select 1, 2, or 3."
MSG_RESTORE_EXTRACTING="📦 Extracting backup archive..."
MSG_RESTORE_EXTRACT_FAILED="❌ Archive extraction failed."
MSG_RESTORE_EXTRACT_COMPLETE="✅ Archive extraction completed."
MSG_RESTORE_LOG_SAVED="📜 Restore log saved: %s"
MSG_RESTORE_HISTORY_UPDATED="📊 Restore history updated: %s"
MSG_RESTORE_FULL_SYNC_WARNING="🔥 Running in full sync mode. (Files not in backup will be deleted, but excluded paths are protected)"
MSG_RESTORE_SYNC_START="🔄 Starting file synchronization..."
MSG_RESTORE_SYNC_COMPLETE="📊 Processing complete: %s files synchronized, size: %s, efficiency: %sx"

# ======================
# Additional Install Messages
# ======================

MSG_INSTALL_BASH_COMPLETION_SETUP="Setting up bash-completion system..."
MSG_INSTALL_BASH_COMPLETION_INSTALLED="bash-completion package already installed"
MSG_INSTALL_BASH_COMPLETION_ACTIVE="bash completion already activated"
MSG_INSTALL_BASH_COMPLETION_COMPLETE="bash-completion system setup completed"
MSG_INSTALL_COMPLETION_TITLE="🚀 To use auto-completion immediately:"
MSG_INSTALL_CONTAINER_ENV_DETECTED="📦 Container environment detected"
MSG_INSTALL_BASH_ENV_DETECTED="🐚 Bash environment detected"
MSG_INSTALL_ZSH_ENV_DETECTED="🐚 ZSH environment detected"
MSG_INSTALL_SHELL_ENV="🐚 Shell environment: %s"
MSG_INSTALL_COMPLETION_CHOOSE_ONE="Choose one of the following:"
MSG_INSTALL_COMPLETION_RELOAD_BASHRC="1) source ~/.bashrc              # Reload configuration file"
MSG_INSTALL_COMPLETION_LOAD_DIRECT="2) source /etc/bash_completion   # Load completion directly"  
MSG_INSTALL_COMPLETION_NEW_SESSION="3) exec bash                     # Start new shell session (recommended)"
MSG_INSTALL_COMPLETION_RELOAD_ZSHRC="1) source ~/.zshrc               # Reload configuration file"
MSG_INSTALL_COMPLETION_REINIT_ZSH="2) autoload -U compinit && compinit  # Re-initialize completion"
MSG_INSTALL_COMPLETION_NEW_ZSH="3) exec zsh                      # Start new shell session (recommended)"
MSG_INSTALL_COMPLETION_COPY_TIP="💡 Copy and paste the command into your terminal"
MSG_INSTALL_COMPLETION_TIP="💡 Press Tab to use auto-completion!"
MSG_INSTALL_USAGE_EXAMPLES="📖 tarsync command usage:"
MSG_INSTALL_USAGE_HELP="      tarsync help                    # Show help"
MSG_INSTALL_USAGE_VERSION="      tarsync version                 # Check version"  
MSG_INSTALL_USAGE_BACKUP="      tarsync backup /home/user       # Backup directory"
MSG_INSTALL_USAGE_LIST="      tarsync list                    # List backups"

# ======================  
# List Module Messages
# ======================

MSG_LIST_LOADING="📋 Loading backup list..."
MSG_LIST_NO_BACKUPS="⚠️  No backup files found."
MSG_LIST_BACKUP_NOT_FOUND_IDENTIFIER="❌ Backup number %s not found."
MSG_LIST_BACKUP_NOT_EXISTS="❌ Backup does not exist: %s"
MSG_LIST_LOG_USAGE="Usage: tarsync log <number|backup_name>"
MSG_LIST_SPECIFY_BACKUP="❌ Please specify backup number or name."
MSG_LIST_DELETE_CONFIRM="🗑️  Backup deletion confirmation"
MSG_LIST_DELETE_PROMPT="Do you really want to delete this backup? [y/N]: "
MSG_LIST_DELETE_SPECIFY="❌ Please specify the backup name to delete."

# ======================
# Common module messages  
# ======================

MSG_COMMON_COMMAND_FAILED="❌ Command execution failed: %s"
MSG_COMMON_STORE_DIR_CREATING="📁 Creating backup storage: %s"
MSG_COMMON_BACKUP_SIZE_RECORDED="📦 Backup file size recorded in metadata: %s"
MSG_COMMON_METADATA_NOT_FOUND="❌ Metadata file not found: %s"
MSG_COMMON_SIZE_CALCULATING="📊 Calculating backup size..."
MSG_COMMON_EXCLUDE_PATH_SIZE="  Excluded path '%s': %s"
MSG_COMMON_EXCLUDE_PATH_DIFFERENT_FS="  Excluded path '%s': different filesystem or does not exist"
MSG_COMMON_TOTAL_SIZE="  Total size: %s"
MSG_COMMON_FINAL_BACKUP_SIZE="  Final backup size: %s"
MSG_COMMON_PROGRESS_START="🚀 %s starting..."
MSG_COMMON_PROGRESS_COMMAND="   Command: %s"
MSG_COMMON_PROGRESS_COMPLETE="✅ %s completed!"
MSG_COMMON_PROGRESS_FAILED="❌ %s failed!"
