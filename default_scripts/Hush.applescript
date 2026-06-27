tell application "Pro Tools" to activate
tell application "System Events"
    tell process "Pro Tools"
        ---------------------------------------------------------
        -- 1. CLICK THE HUSH MIX AUDIOSUITE MENU ITEM
        ---------------------------------------------------------
        try
            click menu item "Hush Mix" of menu of menu item "Noise Reduction" of menu "AudioSuite" of menu bar 1
        on error
            display dialog "Could not find 'Hush Mix' under AudioSuite > Noise Reduction." buttons {"OK"} default button 1
            return
        end try

        ---------------------------------------------------------
        -- 2. WAIT FOR THE WINDOW TO APPEAR
        ---------------------------------------------------------
        set windowFound to false
        repeat 15 times
            if exists (first window whose title contains "Hush Mix") then
                set windowFound to true
                exit repeat
            end if
            delay 0.1
        end repeat

        if not windowFound then return

        ---------------------------------------------------------
        -- 3. LOAD "MAX" PRESET
        ---------------------------------------------------------
        tell window "Audio Suite: Hush Mix"
            click pop up button "Preset"
            delay 0.3
        end tell
        keystroke "m"
        delay 0.2
        key code 36
        delay 0.3

        ---------------------------------------------------------
        -- 4. CLICK RENDER
        ---------------------------------------------------------
        tell window "Audio Suite: Hush Mix"
            if exists button "Render" then
                click button "Render"
            end if
        end tell
    end tell
end tell
