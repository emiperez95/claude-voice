#!/bin/bash

# Configure Sound Mode for Claude Voice Notifier
# Interactive script to set notification preferences

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/sound.conf"
VOICE_SCRIPT="$SCRIPT_DIR/voice_notifier.sh"

# Current mode
CURRENT_MODE="voice"

# Check if config exists and load current mode
if [ -f "$CONFIG_FILE" ]; then
    mode_line=$(grep "^MODE=" "$CONFIG_FILE" 2>/dev/null || echo "")
    if [ -n "$mode_line" ]; then
        CURRENT_MODE="${mode_line#MODE=}"
    fi
fi

echo ""
echo -e "${BLUE}Claude Voice Notifier - Sound Configuration${NC}"
echo "==========================================="
echo ""

echo -e "${GREEN}Current mode: $CURRENT_MODE${NC}"
echo ""

echo "Select notification mode:"
echo "  1) Voice - Spoken notifications (default)"
echo "  2) Glass - macOS Glass sound"
echo "  3) None  - Silent mode"
echo ""

read -p "Enter choice (1-3): " choice

case $choice in
    1)
        NEW_MODE="voice"
        echo -e "${GREEN}✓ Selected: Voice notifications${NC}"
        ;;
    2)
        NEW_MODE="glass"
        echo -e "${GREEN}✓ Selected: Glass sound${NC}"
        ;;
    3)
        NEW_MODE="none"
        echo -e "${GREEN}✓ Selected: Silent mode${NC}"
        ;;
    *)
        echo -e "${RED}Invalid choice. Keeping current mode: $CURRENT_MODE${NC}"
        exit 1
        ;;
esac

# Test the selected mode
echo ""
echo -e "${YELLOW}Testing notification...${NC}"

# Save the new mode temporarily
echo "MODE=$NEW_MODE" > "$CONFIG_FILE.tmp"
mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"

# Run test notification
echo '{"test": true}' | bash "$VOICE_SCRIPT" stop

echo ""
read -p "Keep this setting? (y/n): " confirm

if [[ $confirm =~ ^[Yy]$ ]]; then
    echo "MODE=$NEW_MODE" > "$CONFIG_FILE"
    echo -e "${GREEN}✅ Configuration saved!${NC}"
    echo -e "${GREEN}   Mode: $NEW_MODE${NC}"
    echo -e "${GREEN}   File: $CONFIG_FILE${NC}"
else
    # Restore previous mode
    if [ "$CURRENT_MODE" != "$NEW_MODE" ]; then
        echo "MODE=$CURRENT_MODE" > "$CONFIG_FILE"
    fi
    echo -e "${YELLOW}Configuration cancelled. Restored previous mode: $CURRENT_MODE${NC}"
fi

echo ""
echo "To test your configuration, run: ./test_voice.sh"
echo ""