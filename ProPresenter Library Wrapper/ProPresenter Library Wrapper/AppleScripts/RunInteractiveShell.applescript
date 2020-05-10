on getExitCode(terminalOutput)
    set contentsOfTerminalOutput to contents of contents of terminalOutput
    tell me to set the text item delimiters to (ASCII character 10)
    set terminalOutputByLine to text items of contentsOfTerminalOutput
    
    tell me to set the text item delimiters to "¬"
    repeat with terminalLine in terminalOutputByLine
        if terminalLine contains "EXITCODE¬" then
            if text item 1 of terminalLine is "EXITCODE" then
                set exitCode to text item 2 of terminalLine
                tell me to set the text item delimiters to ""
                return exitCode as number
            end if
        end if
    end repeat
end getExitCode


on runInteractiveTerminalApp(pathToShScript as string)
    set posixPathToShScript to POSIX file pathToShScript as alias
    
    tell application "Finder"
        set parentPath to POSIX path of (parent of posixPathToShScript as string)
        set fileName to name of posixPathToShScript
    end tell
    
    if application "Terminal" is running then
        tell application "Terminal"
            activate
            set openNewWindow to do script ""
            repeat
                delay 0.1
                if not busy of openNewWindow then exit repeat
            end repeat
            set activeWindow to window 1
        end tell
    else
        tell application "Terminal"
            activate
            set activeWindow to window 1
        end tell
    end if
    
    tell application "Terminal"
        set cdScript to do script "cd \"" & parentPath & "\"" in activeWindow
        repeat
            delay 0.5
            if not busy of cdScript then exit repeat
        end repeat
        
        set shScript to do script "./" & fileName in activeWindow
        repeat
            delay 0.5
            if not busy of shScript then exit repeat
        end repeat
        
        set checkSuccess to do script "echo \"EXITCODE¬$?\"" in activeWindow
        repeat
            delay 0.5
            if not busy of checkSuccess then exit repeat
        end repeat
    end tell
    
    set exitCode to getExitCode(checkSuccess)
    
    if exitCode = 0 then
        tell application "Terminal"
            close activeWindow
            set theWindows to windows
            set windowsCount to count of theWindows
            if windowsCount = 0 then
                quit
            end if
        end tell
    end if
    
    return exitCode
end runInteractiveTerminalApp
