tell application "Pro Tools" to activate
tell application "System Events"
    tell process "Pro Tools"
        ---------------------------------------------------------
        -- 1. OPEN RX 11 CONNECT VIA THE AUDIOSUITE MENU
        ---------------------------------------------------------
        try
            click menu item "RX 11 Connect" of menu "Noise Reduction" of menu item "Noise Reduction" of menu "AudioSuite" of menu bar 1
        on error
            display dialog "PT Launcher couldn't find \"RX 11 Connect\" under AudioSuite > Noise Reduction." & return & return & "Make sure iZotope RX Connect is installed, and that the AudioSuite menu item is named exactly \"RX 11 Connect\" (the name changes with your RX version)." buttons {"OK"} default button 1
            return
        end try

        ---------------------------------------------------------
        -- 2. WAIT FOR THE RX CONNECT WINDOW TO APPEAR
        ---------------------------------------------------------
        set rxWindowFound to false
        repeat 20 times
            if exists (first window whose title contains "RX 11 Connect") then
                set rxWindowFound to true
                exit repeat
            end if
            delay 0.1
        end repeat

        if not rxWindowFound then
            display dialog "PT Launcher opened RX 11 Connect, but its window didn't appear." & return & return & "Make sure a clip is selected on a track, then try again." buttons {"OK"} default button 1
            return
        end if

        ---------------------------------------------------------
        -- 3. CLICK SEND (internally named "Analyze")
        ---------------------------------------------------------
        try
            click button "Analyze" of window "Audio Suite: RX 11 Connect"
        on error
            display dialog "PT Launcher opened RX 11 Connect but couldn't find the Send button." & return & return & "Open the RX 11 Connect window and check that the Send/Analyze button is visible, then try again." buttons {"OK"} default button 1
            return
        end try
    end tell
end tell
