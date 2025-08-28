#!/bin/bash

# ===== Tarsync Uninstaller =====
# ===== Tarsync Uninstaller =====

# Load utility modules
# Load utility modules
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$PROJECT_ROOT/src/utils/colors.sh"
source "$PROJECT_ROOT/src/utils/log.sh"

# Language detection and message system loading
source "$PROJECT_ROOT/config/messages/detect.sh"
source "$PROJECT_ROOT/config/messages/load.sh"

# Initialize message system
load_tarsync_messages


# Installation paths (Global installation)
# Installation paths (Global installation)
PROJECT_DIR="/usr/share/tarsync"
INSTALL_DIR="/usr/local/bin"
COMPLETION_DIR="/etc/bash_completion.d"
ZSH_COMPLETION_DIR="/usr/share/zsh/site-functions"
CONFIG_DIR="/etc/tarsync"

# Check sudo privileges
check_sudo_privileges() {
    if [ "$EUID" -ne 0 ]; then
        error_msg "MSG_INSTALL_SUDO_REQUIRED"
        msg "MSG_INSTALL_SUDO_HINT"
        exit 1
    fi
}

# Remove tarsync files (Global installation)
# Remove tarsync files (Global installation)
remove_tarsync() {
    msg "MSG_UNINSTALL_START"
    
    # Remove executable
    if [ -f "$INSTALL_DIR/tarsync" ]; then
        rm -f "$INSTALL_DIR/tarsync"
        msg "MSG_SYSTEM_REMOVING_FILE" "$INSTALL_DIR/tarsync"
    fi
    
    # Remove project directory
    if [ -d "$PROJECT_DIR" ]; then
        rm -rf "$PROJECT_DIR"
        msg "MSG_SYSTEM_REMOVING_FILE" "$PROJECT_DIR"
    fi
    
    # Remove configuration directory
    if [ -d "$CONFIG_DIR" ]; then
        rm -rf "$CONFIG_DIR"
        msg "MSG_SYSTEM_REMOVING_FILE" "$CONFIG_DIR"
    fi
    
    # Remove completion files
    if [ -f "$COMPLETION_DIR/tarsync" ]; then
        rm -f "$COMPLETION_DIR/tarsync"
        msg "MSG_SYSTEM_REMOVING_FILE" "$COMPLETION_DIR/tarsync"
    fi
    
    if [ -f "$ZSH_COMPLETION_DIR/_tarsync" ]; then
        rm -f "$ZSH_COMPLETION_DIR/_tarsync"
        msg "MSG_SYSTEM_REMOVING_FILE" "$ZSH_COMPLETION_DIR/_tarsync"
    fi
    
    success_msg "MSG_UNINSTALL_COMPLETE"
}

# Remove tarsync from PATH (Not needed for global installation)
# Remove tarsync from PATH (Not needed for global installation)
remove_from_path() {
    msg "MSG_INSTALL_PATH_NOT_NEEDED"
}

# Remove completion settings (Already removed from system files in global installation)
# Remove completion settings (Already removed from system files in global installation)
remove_completion_settings() {
    msg "MSG_INSTALL_COMPLETION_BASH_COMPLETE"
}

# Verify uninstallation (Global installation)
# Verify uninstallation (Global installation)
verify_uninstallation() {
    local issues=()
    
    # Check executable
    if [ -f "$INSTALL_DIR/tarsync" ]; then
        issues+=("$(msg MSG_INSTALL_SCRIPT_NOT_FOUND "$INSTALL_DIR/tarsync")")
    fi
    
    # Check project directory
    if [ -d "$PROJECT_DIR" ]; then
        issues+=("$(msg MSG_SYSTEM_DIRECTORY_EXISTS "$PROJECT_DIR")")
    fi
    
    # Check configuration directory
    if [ -d "$CONFIG_DIR" ]; then
        issues+=("$(msg MSG_SYSTEM_DIRECTORY_EXISTS "$CONFIG_DIR")")
    fi
    
    # Check completion files
    if [ -f "$COMPLETION_DIR/tarsync" ]; then
        issues+=("$(msg MSG_SYSTEM_FILE_EXISTS "$COMPLETION_DIR/tarsync")")
    fi
    
    if [ -f "$ZSH_COMPLETION_DIR/_tarsync" ]; then
        issues+=("$(msg MSG_SYSTEM_FILE_EXISTS "$ZSH_COMPLETION_DIR/_tarsync")")
    fi
    
    if [ ${#issues[@]} -gt 0 ]; then
        warn_msg "MSG_UNINSTALL_ISSUES_FOUND"
        for issue in "${issues[@]}"; do
            echo "  • $issue"
        done
        echo ""
        msg "MSG_UNINSTALL_MANUAL_CLEANUP_NEEDED"
        return 1
    else
        success_msg "MSG_UNINSTALL_COMPLETE"
        return 0
    fi
}

# User confirmation (Global installation)
# User confirmation (Global installation)
confirm_uninstall() {
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║          $(msg MSG_UNINSTALL_HEADER_TITLE)             ║${NC}"
    echo -e "${CYAN}║     $(msg MSG_INSTALL_HEADER_SUBTITLE)           ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    warn_msg "MSG_UNINSTALL_ITEMS_TO_REMOVE"
    msg "MSG_INSTALL_LOCATION_EXECUTABLE" "$INSTALL_DIR/tarsync"
    msg "MSG_INSTALL_LOCATION_LIBRARY" "$PROJECT_DIR"
    msg "MSG_UNINSTALL_CONFIG_DIR" "$CONFIG_DIR"
    msg "MSG_INSTALL_LOCATION_BASH_COMPLETION" "$COMPLETION_DIR/tarsync"
    msg "MSG_INSTALL_LOCATION_ZSH_COMPLETION" "$ZSH_COMPLETION_DIR/_tarsync"
    echo ""
    
    printf "$(msg MSG_UNINSTALL_CONFIRM)"
    read -r confirmation
    
    if [[ $confirmation =~ ^[Yy]$ ]]; then
        return 0
    else
        msg "MSG_UNINSTALL_CANCELLED"
        exit 0
    fi
}

# Main uninstall process (Global installation)
# Main uninstall process (Global installation)
main() {
    # Check sudo privileges
    check_sudo_privileges
    
    # User confirmation
    confirm_uninstall
    
    echo ""
    msg "MSG_UNINSTALL_START"
    echo ""
    
    # Sequential removal
    remove_tarsync || {
        error_msg "MSG_UNINSTALL_FAILED"
        exit 1
    }
    
    remove_from_path
    remove_completion_settings
    
    echo ""
    msg "MSG_INSTALL_VERIFYING"
    
    # Verify removal
    if verify_uninstallation; then
        echo ""
        success_msg "MSG_UNINSTALL_COMPLETE"
        echo ""
        msg "MSG_UNINSTALL_RESTART_TERMINAL"
        echo ""
    else
        echo ""
        warn_msg "MSG_UNINSTALL_MANUAL_CLEANUP_NEEDED"
        exit 1
    fi
}

# Execute main function
# Execute main function
main 