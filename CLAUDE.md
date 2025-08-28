# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a standalone voice notification system for Claude Code that announces when Claude stops executing or needs user attention using macOS text-to-speech.

## Commands

### Testing Voice Notifications
```bash
./test_voice.sh  # Tests both stop and notification events
```

### Sound Configuration
```bash
./configure_sound.sh  # Interactive sound mode configuration
```

### Installation Management
```bash
./install.sh              # Interactive installation (requires jq)
./install.sh --dry-run    # Preview changes without applying
./install.sh --force      # Overwrite existing hooks without prompting
./uninstall.sh            # Remove voice notifications
./uninstall.sh --dry-run  # Preview uninstall changes
```

### Manual Testing
```bash
# Test the voice notifier directly
echo '{}' | bash voice_notifier.sh stop         # Test stop notification
echo '{}' | bash voice_notifier.sh notification # Test attention notification

# Test with different modes (create sound.conf first)
echo 'MODE=bell' > sound.conf  # Switch to bell mode
echo 'MODE=none' > sound.conf  # Switch to silent mode
echo 'MODE=voice' > sound.conf # Switch to voice mode
```

## Architecture

The system consists of four main components:

1. **voice_notifier.sh** - The core notification script
   - Pure bash implementation (no Python dependencies)
   - Reads JSON from stdin (consumed but not parsed)
   - Detects tmux sessions via `$TMUX` environment variable
   - Supports three sound modes: voice, bell, and none
   - Reads configuration from optional `sound.conf` file
   - Event types: `stop` and `notification`

2. **Installation Scripts** - Automated JSON manipulation
   - Both `install.sh` and `uninstall.sh` require `jq` for JSON processing
   - Scripts modify `~/.claude/settings.json` (global settings) to add/remove hooks
   - Preserve existing settings and create backups before changes
   - Check for conflicting hooks with `voice_notifier.*` pattern
   - Handle the global settings array structure for Stop and Notification events

3. **Hook Integration** - Claude Code event system
   - Hooks are configured in `~/.claude/settings.json` (global settings)
   - Uses the array-based hook structure for Stop and Notification events
   - Claude passes JSON data to stdin when events trigger
   - Commands use absolute paths to the voice_notifier.sh script

4. **Sound Configuration** - User preference management
   - `configure_sound.sh` provides interactive configuration
   - Settings stored in local `sound.conf` file (gitignored)
   - Supports voice, bell, and none modes
   - Configuration persists across sessions

## Key Implementation Details

- All scripts check for `voice_notifier.*` (with dot) to handle both `.py` and `.sh` versions
- The installer uses `jq` for safe JSON manipulation (no Python fallback)
- Manual installation is always available for users without jq
- Scripts are executable by default (`chmod +x` already applied)
- Tmux session detection uses alphabetical ordering of session names instead of internal session IDs
- Session numbers are 0-based (starting from 0) and determined by alphabetical position in `tmux list-sessions | sort` output

## Customization Points

### Sound Modes
Configure notification sounds via `sound.conf` file:
- `MODE=voice` - Spoken notifications (default)
- `MODE=bell` - Terminal bell sound
- `MODE=none` - Silent mode

### Voice Messages
Voice messages can be modified in `voice_notifier.sh` in the `handle_stop()` and `handle_notification()` functions. The current messages are:
- "Claude has stopped [in session N]" (where N is 0-based session index)
- "Claude needs your attention [in session N]" (where N is 0-based session index)