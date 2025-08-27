#!/bin/bash

# Voice Notifier for Claude Code
# Provides audio notifications when Claude stops or needs attention

set -e

# Get the current tmux session index if in tmux (based on alphabetical order)
get_tmux_session_index() {
    if [ -n "$TMUX" ]; then
        # Get current session name
        session_name=$(tmux display-message -p '#{session_name}' 2>/dev/null || echo "")
        if [ -n "$session_name" ]; then
            # Get position in sorted list (1-based index)
            position=$(tmux list-sessions -F '#{session_name}' 2>/dev/null | sort | grep -n "^${session_name}$" | cut -d: -f1)
            if [ -n "$position" ]; then
                echo "$position"
                return 0
            fi
        fi
    fi
    return 1
}

# Speak a message using macOS say command
speak() {
    local message="$1"
    say "$message" 2>/dev/null || {
        echo "[VOICE ERROR] Failed to speak: $message" >&2
    }
}

# Handle stop event
handle_stop() {
    if session_index=$(get_tmux_session_index); then
        speak "Claude has stopped in session $session_index"
    else
        speak "Claude has stopped"
    fi
}

# Handle notification event
handle_notification() {
    if session_index=$(get_tmux_session_index); then
        speak "Claude needs your attention in session $session_index"
    else
        speak "Claude needs your attention"
    fi
}

# Main logic
main() {
    # Read JSON from stdin (we don't actually use it, but need to consume it)
    cat > /dev/null
    
    # Get event type from command line argument
    event_type="${1:-unknown}"
    
    case "$event_type" in
        stop)
            handle_stop
            ;;
        notification)
            handle_notification
            ;;
        *)
            echo "[VOICE ERROR] Unknown event type: $event_type" >&2
            exit 1
            ;;
    esac
    
    exit 0
}

# Run main function
main "$@"