tell application "Pro Tools" to activate
tell application "System Events"
    tell process "Pro Tools"
        -- Open RX Connect via menu
        click menu item "RX 11 Connect" of menu "Noise Reduction" of menu item "Noise Reduction" of menu "AudioSuite" of menu bar 1

        -- Wait for window to appear
        delay 1

        -- Click Send (internally named Analyze)
        click button "Analyze" of window "Audio Suite: RX 11 Connect"
    end tell
end tell
