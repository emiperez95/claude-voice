#!/bin/bash

# Claude Voice Notifier - Automated Installation Script
# Automatically configures voice notifications in Claude Code using pure bash

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get the absolute path to this project
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
VOICE_SCRIPT="$PROJECT_DIR/voice_notifier.sh"
SETTINGS_FILE="$HOME/.claude/settings.json"

# Parse command line arguments
DRY_RUN=false
FORCE=false
for arg in "$@"; do
    case $arg in
        --dry-run)
            DRY_RUN=true
            ;;
        --force)
            FORCE=true
            ;;
        --help|-h)
            echo "Claude Voice Notifier - Installation"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --dry-run    Preview changes without modifying files"
            echo "  --force      Overwrite existing hooks without prompting"
            echo "  --help       Show this help message"
            echo ""
            echo "This installer will add voice notification hooks to your Claude Code setup."
            echo "Hooks will be added to: $SETTINGS_FILE"
            echo ""
            echo "Manual Installation:"
            echo "  If you prefer manual installation, add these to ~/.claude/settings.json:"
            echo "  {"
            echo "    \"hooks\": {"
            echo "      \"stop\": {"
            echo "        \"command\": \"bash $VOICE_SCRIPT stop\""
            echo "      },"
            echo "      \"notification\": {"
            echo "        \"command\": \"bash $VOICE_SCRIPT notification\""
            echo "      }"
            echo "    }"
            echo "  }"
            exit 0
            ;;
    esac
done

echo ""
echo -e "${BLUE}Claude Voice Notifier - Automated Installation${NC}"
echo "==============================================="
echo ""

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}🔍 DRY RUN MODE - No changes will be made${NC}"
    echo ""
fi

if [ "$FORCE" = true ]; then
    echo -e "${YELLOW}⚠️  FORCE MODE - Will overwrite existing hooks${NC}"
    echo ""
fi

# Check if voice_notifier.sh exists
if [ ! -f "$VOICE_SCRIPT" ]; then
    echo -e "${RED}Error: voice_notifier.sh not found in $PROJECT_DIR${NC}"
    exit 1
fi

# Check for macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${YELLOW}Warning: This tool uses macOS 'say' command for voice output.${NC}"
    echo "It may not work properly on non-macOS systems."
    echo ""
    if [ "$FORCE" = false ] && [ "$DRY_RUN" = false ]; then
        read -p "Continue anyway? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
fi

# Check for jq (required for automated installation)
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is required for automated installation${NC}"
    echo ""
    echo "To install jq on macOS:"
    echo "  brew install jq"
    echo ""
    echo "Or use manual installation by adding the hooks directly to:"
    echo "  ~/.claude/settings.json"
    echo ""
    echo "Run with --help to see manual installation instructions."
    exit 1
fi
echo -e "${GREEN}✓ Found jq for JSON processing${NC}"

# Function to merge JSON using jq (for global settings structure)
merge_hooks() {
    local current_json="$1"
    local voice_script="$2"
    
    # Use jq to add/update voice notifier hooks in global settings format
    echo "$current_json" | jq \
        --arg stop_cmd "bash $voice_script stop" \
        --arg notif_cmd "bash $voice_script notification" \
        '
        # Ensure hooks structure exists
        .hooks = (.hooks // {}) |
        
        # Add/update Stop hook - keep existing hooks but replace voice_notifier
        .hooks.Stop = (
            if .hooks.Stop then
                .hooks.Stop | map(
                    .hooks = (.hooks | map(
                        if (.command | contains("voice_notifier")) then
                            .command = $stop_cmd
                        else . end
                    ))
                )
            else
                [{hooks: [{type: "command", command: $stop_cmd}]}]
            end
        ) |
        
        # If voice_notifier not found in Stop, add it
        if (.hooks.Stop[0].hooks | map(.command | contains("voice_notifier")) | any | not) then
            .hooks.Stop[0].hooks += [{type: "command", command: $stop_cmd}]
        else . end |
        
        # Add/update Notification hook
        .hooks.Notification = [{hooks: [{type: "command", command: $notif_cmd}]}]
        '
}

# Check existing hooks
check_conflicts() {
    local current_json="$1"
    local voice_script="$2"
    
    # Check for existing voice notifier hooks
    local stop_voice=$(echo "$current_json" | jq -r '(.hooks.Stop // [])[0].hooks[]? | select(.command | contains("voice_notifier")) | .command')
    local notif_voice=$(echo "$current_json" | jq -r '(.hooks.Notification // [])[0].hooks[]? | select(.command | contains("voice_notifier")) | .command')
    
    if [ -n "$stop_voice" ]; then
        echo -e "${YELLOW}⚠ Existing 'stop' voice hook found: $stop_voice${NC}"
        echo -e "${GREEN}  Will replace with: bash $voice_script stop${NC}"
    fi
    
    if [ -n "$notif_voice" ]; then
        echo -e "${YELLOW}⚠ Existing 'notification' voice hook found: $notif_voice${NC}"
        echo -e "${GREEN}  Will replace with: bash $voice_script notification${NC}"
    fi
}

# Load current settings or create empty JSON
if [ -f "$SETTINGS_FILE" ]; then
    CURRENT_JSON=$(cat "$SETTINGS_FILE")
    echo -e "${GREEN}✓ Found existing settings file${NC}"
else
    CURRENT_JSON="{}"
    echo -e "${YELLOW}✓ Will create new settings file${NC}"
fi

# Check for conflicts
check_conflicts "$CURRENT_JSON" "$VOICE_SCRIPT"

# Merge the hooks
NEW_JSON=$(merge_hooks "$CURRENT_JSON" "$VOICE_SCRIPT")

if [ "$DRY_RUN" = true ]; then
    echo ""
    echo -e "${BLUE}Preview of changes:${NC}"
    echo "-------------------"
    echo "$NEW_JSON"
    echo "-------------------"
    echo ""
    echo -e "${BLUE}Dry run complete. Run without --dry-run to apply changes.${NC}"
else
    # Create backup if file exists
    if [ -f "$SETTINGS_FILE" ]; then
        BACKUP_FILE="$SETTINGS_FILE.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$SETTINGS_FILE" "$BACKUP_FILE"
        echo -e "${GREEN}📁 Settings backed up to: $BACKUP_FILE${NC}"
    fi
    
    # Ensure directory exists
    mkdir -p "$(dirname "$SETTINGS_FILE")"
    
    # Write the new settings
    echo "$NEW_JSON" > "$SETTINGS_FILE"
    
    echo ""
    echo -e "${GREEN}✅ Installation successful!${NC}"
    echo -e "${GREEN}📍 Settings file: $SETTINGS_FILE${NC}"
    echo ""
    echo "To test voice notifications, run: ./test_voice.sh"
    echo "To uninstall, run: ./uninstall.sh"
fi

echo ""