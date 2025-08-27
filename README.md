# 🔊 Claude Voice Notifier

Standalone audio notifications for Claude Code using macOS text-to-speech. Get voice alerts when Claude stops executing or needs your attention.

## ✨ Features

- **Stop Notifications**: Announces when Claude has finished executing
- **Attention Alerts**: Notifies when Claude needs user input
- **Tmux Integration**: Announces session number when running in tmux
- **Sound Modes**: Choose between voice, bell, or silent notifications
- **Pure Bash**: No Python or external dependencies for the notifier
- **Lightweight**: Simple bash scripts using macOS built-in `say` command

## 📋 Requirements

- **macOS** (uses the built-in `say` command)
- **jq** (for automated installation) - Install with: `brew install jq`
- **Optional**: tmux for session identification

## 🚀 Quick Start

### Installation

1. Clone this repository:
```bash
git clone https://github.com/yourusername/claude-voice.git
cd claude-voice
```

2. Run the automated installation:
```bash
./install.sh
```

The installer will automatically configure your `.claude/settings.json` with the necessary hooks.

### Testing

Test that voice notifications are working:
```bash
./test_voice.sh
```

You should hear:
- "Claude has stopped" (or with session number if in tmux)
- "Claude needs your attention"

### Uninstallation

To remove voice notifications:
```bash
./uninstall.sh
```

This will remove the hooks from your Claude settings while preserving all other configurations.

## 🔧 Installation Options

### Automated Installation (Requires jq)

The automated installer requires `jq` for JSON manipulation. If you don't have jq installed:
```bash
brew install jq
```

Then run the installer:
```bash
./install.sh              # Interactive installation
./install.sh --dry-run    # Preview changes without applying
./install.sh --force      # Overwrite existing hooks without prompting
./install.sh --help       # Show all available options
```

### Manual Installation (No jq required)

If you don't want to install jq, you can manually edit your `~/.claude/settings.json` file:

1. Open or create `~/.claude/settings.json`
2. Add or merge the following hooks in the global settings format:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash /absolute/path/to/claude-voice/voice_notifier.sh stop"
          }
        ]
      }
    ],
    "Notification": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash /absolute/path/to/claude-voice/voice_notifier.sh notification"
          }
        ]
      }
    ]
  }
}
```

**Note**: If you already have other hooks in the `Stop` array, add the voice notifier as an additional hook in the existing array.

**Important**: Replace `/absolute/path/to/claude-voice/` with the actual full path to your claude-voice directory.

## 📁 Project Structure

```
claude-voice/
├── voice_notifier.sh   # Main notification script (pure bash)
├── configure_sound.sh  # Sound mode configuration script
├── install.sh          # Automated installation script (requires jq)
├── uninstall.sh        # Automated uninstallation script (requires jq)
├── test_voice.sh       # Test script
├── sound.conf          # Sound mode configuration (gitignored)
└── README.md           # This file
```

## 🎯 How It Works

1. Claude Code triggers hooks on specific events (stop, notification)
2. The hook passes event data to `voice_notifier.sh` via stdin
3. The bash script uses macOS `say` command to speak the notification
4. If running in tmux, it includes the session number based on alphabetical ordering of session names

## 🔊 Customization

### Sound Modes

Configure your preferred notification sound using `./configure_sound.sh`:

- **voice** (default): Spoken notifications using macOS `say` command
- **bell**: Terminal bell sound
- **none**: Silent mode (no notifications)

The configuration is stored in `sound.conf` (gitignored for personal preferences).

You can also manually create/edit `sound.conf`:
```bash
MODE=voice  # Options: voice, bell, none
```

### Voice Messages

To modify the voice messages, edit the `handle_stop()` and `handle_notification()` functions in `voice_notifier.sh`:

```bash
# Current messages in the script:
speak "Claude has stopped in session $session_index"
speak "Claude needs your attention in session $session_index"
```

## 🤝 Integration with agent-workflow

This is a standalone extraction from the [agent-workflow](https://github.com/yourusername/agent-workflow) project. If you have agent-workflow installed, voice notifications are already included. This standalone version allows you to use voice notifications without the full workflow system.

## 🐛 Troubleshooting

### No sound heard
- Check system volume is turned up
- Test the `say` command directly: `say "test"`
- Ensure you're on macOS (Linux/Windows not supported)

### Script not found errors
- Use absolute paths in your settings.json
- Ensure the script has execute permissions: `chmod +x voice_notifier.sh`

### Tmux session not detected
- Ensure you're running inside a tmux session
- Check tmux is installed: `tmux -V`

## 📄 License

MIT License - See LICENSE file for details

## 🙏 Credits

Originally developed as part of the Claude Development Pipeline (agent-workflow) project.