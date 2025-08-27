#!/bin/bash

# Test script for Claude Voice Notifier
# Tests both stop and notification voice alerts

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
VOICE_SCRIPT="$PROJECT_DIR/voice_notifier.sh"
CONFIG_FILE="$PROJECT_DIR/sound.conf"

echo ""
echo -e "${BLUE}Claude Voice Notifier - Test Suite${NC}"
echo "===================================="
echo ""

# Display current mode
if [ -f "$CONFIG_FILE" ]; then
    mode_line=$(grep "^MODE=" "$CONFIG_FILE" 2>/dev/null || echo "")
    if [ -n "$mode_line" ]; then
        CURRENT_MODE="${mode_line#MODE=}"
        echo -e "${GREEN}Sound mode: $CURRENT_MODE${NC}"
    else
        echo -e "${GREEN}Sound mode: voice (default)${NC}"
    fi
else
    echo -e "${GREEN}Sound mode: voice (default, no config file)${NC}"
fi
echo ""

# Check if voice_notifier.sh exists
if [ ! -f "$VOICE_SCRIPT" ]; then
    echo -e "${YELLOW}Error: voice_notifier.sh not found${NC}"
    exit 1
fi

# Check for macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${YELLOW}Warning: This tool requires macOS 'say' command${NC}"
fi

echo -e "${GREEN}Testing 'stop' event...${NC}"
echo '{"session_id": "test-session", "timestamp": "2024-01-01T12:00:00"}' | bash "$VOICE_SCRIPT" stop
sleep 2

echo -e "${GREEN}Testing 'notification' event...${NC}"
echo '{"session_id": "test-session", "timestamp": "2024-01-01T12:00:00"}' | bash "$VOICE_SCRIPT" notification
sleep 2

# Test with tmux if available
if command -v tmux &> /dev/null && [ -n "$TMUX" ]; then
    echo -e "${GREEN}Testing with tmux session detection...${NC}"
    echo '{"session_id": "tmux-test"}' | bash "$VOICE_SCRIPT" stop
    sleep 2
fi

echo ""
echo -e "${GREEN}✓ All tests completed!${NC}"
echo ""
echo "If you heard voice notifications, the system is working correctly."
echo "If not, check that:"
echo "  - You're on macOS"
echo "  - System volume is turned up"
echo "  - 'say' command is available (test with: say 'hello')"
echo ""