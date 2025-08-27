#!/bin/bash

# Claude Voice Notifier - Automated Uninstallation Script
# Automatically removes voice notifications from Claude Code using pure bash

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get the absolute path to this project
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
SETTINGS_FILE="$HOME/.claude/settings.json"

# Parse command line arguments
DRY_RUN=false
for arg in "$@"; do
    case $arg in
        --dry-run)
            DRY_RUN=true
            ;;
        --help|-h)
            echo "Claude Voice Notifier - Uninstallation"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --dry-run    Preview changes without modifying files"
            echo "  --help       Show this help message"
            echo ""
            echo "This script will:"
            echo "  - Remove voice notifier hooks from $SETTINGS_FILE"
            echo "  - Create a backup before making changes"
            echo "  - Only remove hooks that contain 'voice_notifier'"
            echo "  - Preserve all other hooks and settings"
            echo ""
            exit 0
            ;;
    esac
done

echo ""
echo -e "${BLUE}Claude Voice Notifier - Automated Uninstallation${NC}"
echo "================================================="
echo ""

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}🔍 DRY RUN MODE - No changes will be made${NC}"
    echo ""
fi

# Check if settings file exists
if [ ! -f "$SETTINGS_FILE" ]; then
    echo -e "${YELLOW}No settings file found at $SETTINGS_FILE${NC}"
    echo "Nothing to uninstall."
    exit 0
fi

# Check for jq (required for automated uninstallation)
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is required for automated uninstallation${NC}"
    echo ""
    echo "To install jq on macOS:"
    echo "  brew install jq"
    echo ""
    echo "Or manually remove the hooks from:"
    echo "  ~/.claude/settings.json"
    echo ""
    exit 1
fi
echo -e "${GREEN}✓ Found jq for JSON processing${NC}"

# Function to check if hooks contain voice_notifier
check_voice_hooks() {
    local current_json="$1"
    
    # Check for voice notifier in global settings structure
    local stop_voice=$(echo "$current_json" | jq -r '(.hooks.Stop // [])[0].hooks[]? | select(.command | contains("voice_notifier")) | .command')
    local notif_voice=$(echo "$current_json" | jq -r '(.hooks.Notification // [])[0].hooks[]? | select(.command | contains("voice_notifier")) | .command')
    
    local found_hooks=false
    
    if [ -n "$stop_voice" ]; then
        echo -e "${GREEN}✓ Found voice notifier 'stop' hook: $stop_voice${NC}"
        found_hooks=true
    fi
    
    if [ -n "$notif_voice" ]; then
        echo -e "${GREEN}✓ Found voice notifier 'notification' hook: $notif_voice${NC}"
        found_hooks=true
    fi
    
    if [ "$found_hooks" = false ]; then
        echo -e "${YELLOW}No voice notifier hooks found in settings${NC}"
        exit 0
    fi
}

# Function to remove voice hooks using jq
remove_hooks() {
    local current_json="$1"
    
    # Remove voice notifier hooks from global settings structure
    local result=$(echo "$current_json" | jq '
        # Remove voice_notifier from Stop hooks array
        if .hooks.Stop then
            .hooks.Stop[0].hooks = (.hooks.Stop[0].hooks | map(select(.command | contains("voice_notifier") | not)))
        else . end |
        # Remove entire Notification array if it only contains voice_notifier
        if .hooks.Notification and (.hooks.Notification[0].hooks | length == 1) and 
           (.hooks.Notification[0].hooks[0].command | contains("voice_notifier")) then
            del(.hooks.Notification)
        elif .hooks.Notification then
            .hooks.Notification[0].hooks = (.hooks.Notification[0].hooks | map(select(.command | contains("voice_notifier") | not)))
        else . end
    ')
    echo "$result"
}

# Load current settings
CURRENT_JSON=$(cat "$SETTINGS_FILE")

# Check if we have voice hooks to remove
check_voice_hooks "$CURRENT_JSON"

# Confirm uninstallation
if [ "$DRY_RUN" = false ]; then
    echo ""
    echo -e "${YELLOW}This will remove voice notification hooks from Claude Code.${NC}"
    read -p "Continue with uninstallation? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Uninstallation cancelled.${NC}"
        exit 0
    fi
fi

# Remove the hooks
NEW_JSON=$(remove_hooks "$CURRENT_JSON")

if [ "$DRY_RUN" = true ]; then
    echo ""
    echo -e "${BLUE}Preview of changes:${NC}"
    echo "-------------------"
    echo "Settings after removal:"
    echo "$NEW_JSON"
    echo "-------------------"
    echo ""
    echo -e "${BLUE}Dry run complete. Run without --dry-run to apply changes.${NC}"
else
    # Create backup
    BACKUP_FILE="$SETTINGS_FILE.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$SETTINGS_FILE" "$BACKUP_FILE"
    echo -e "${GREEN}📁 Settings backed up to: $BACKUP_FILE${NC}"
    
    # Write the new settings
    echo "$NEW_JSON" > "$SETTINGS_FILE"
    
    echo ""
    echo -e "${GREEN}✅ Uninstallation complete!${NC}"
    echo -e "${GREEN}📍 Settings file: $SETTINGS_FILE${NC}"
    echo ""
    echo -e "${YELLOW}Note:${NC} The voice notifier files themselves have not been deleted."
    echo "You can safely delete this directory if you no longer need it:"
    echo "  rm -rf $PROJECT_DIR"
fi

echo ""