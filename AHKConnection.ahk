; AHKConnection.ahk
#NoEnv
#SingleInstance Force
SendMode Input
SetWorkingDir %A_ScriptDir%
CoordMode, Mouse, Screen

if !FileExist("workspace")
{
    MsgBox, Put this file one folder above your exploit's workspace folder then run it again (your exploit folder)
    ExitApp
}

if !FileExist("workspace/Replayability+_AHK")
{
    FileCreateDir, workspace/Replayability+_AHK
    MsgBox, Replayability+_AHK folder has been added to workspace
}

requestFile := "workspace/Replayability+_AHK/Request"
if !FileExist(requestFile)
{
    writefile := FileOpen(requestFile, "w")
    writefile.Write()
    writefile.Close()
    MsgBox, Request file has been added to Replayability+_AHK folder
}

; configuration
frameDelayMs := 1000.0 / 60.0  ; milliseconds per frame (default 60 FPS). Change denominator for other FPS.
trackedKeys := ["W","A","S","D","Space","LeftShift"]

; key token mapping
KeyToken := {}
KeyToken["W"] := "w"
KeyToken["A"] := "a"
KeyToken["S"] := "s"
KeyToken["D"] := "d"
KeyToken["Space"] := "Space"
KeyToken["LeftShift"] := "LShift"

; initialize prev state
prevState := {}
Loop, % trackedKeys.Length()
    prevState[ trackedKeys[A_Index] ] := false

SetKeyDelay, -1, 0

#Persistent
SetTimer, MainLoop, -1
SetTimer, SuccessMessage, -1
return

TrimStr(s) {
    return RegExReplace(s, "^\s+|\s+$", "")
}

SendKeyAction(keyName, action) {
    global KeyToken
    token := KeyToken[keyName] ? KeyToken[keyName] : keyName
    if (action = "down")
        SendInput, % "{" token " down}"
    else
        SendInput, % "{" token " up}"
}

MainLoop:
Loop
{
    raw := ""
    try {
        rf := FileOpen(requestFile, "r")
        if IsObject(rf) {
            raw := rf.Read()
            rf.Close()
        }
    } catch e {
        raw := ""
    }

    if (raw != "")
    {
        for i, token in StrSplit(raw, ",")
        {
            token := TrimStr(token)
            if (token = "")
                continue

            ; wheel tokens
            if (token = "u")
            {
                Send, {WheelUp 1}
                continue
            }
            if (token = "d")
            {
                Send, {WheelDown 1}
                continue
            }

            ; explicit single-key down/up: e.g. "W_down" or "Space_up"
            if RegExMatch(token, "^\s*([%w%p]+)_(down|up)\s*$", m)
            {
                keyRaw := m1
                action := m2
                foundKey := ""
                StringUpper, keyCheck, keyRaw
                for idx, k in trackedKeys {
                    StringUpper, kUp, k
                    if (keyCheck = kUp) {
                        foundKey := k
                        break
                    }
                }
                if (foundKey = "")
                    foundKey := keyRaw
                SendKeyAction(foundKey, action)
                if (foundKey != "" && foundKey in trackedKeys) {
                    if (action = "down")
                        prevState[foundKey] := true
                    else
                        prevState[foundKey] := false
                }
                continue
            }

            ; bracketed frame token: [W,A,Space] or [W A Space]
            if RegExMatch(token, "^\s*\[(.*)\]\s*$", m)
            {
                inner := m1
                inner := RegExReplace(inner, ",", " ")
                currentState := {}
                for keyIndex, keyName in trackedKeys
                    currentState[keyName] := false

                for j, part in StrSplit(inner, " ")
                {
                    part := TrimStr(part)
                    if (part = "") 
                        continue
                    StringUpper, pUp, part
                    for keyIndex, keyName in trackedKeys
                    {
                        StringUpper, kUp, keyName
                        if (pUp = kUp) {
                            currentState[keyName] := true
                            break
                        }
                    }
                }

                for keyIndex, keyName in trackedKeys
                {
                    if currentState[keyName] and !prevState[keyName]
                    {
                        SendKeyAction(keyName, "down")
                        prevState[keyName] := true
                    }
                    if !currentState[keyName] and prevState[keyName]
                    {
                        SendKeyAction(keyName, "up")
                        prevState[keyName] := false
                    }
                }

                Sleep, % frameDelayMs
                continue
            }

            ; unrecognized token -> ignore
        }

        ; clear Request after processing
        try {
            wf := FileOpen(requestFile, "w")
            if IsObject(wf) {
                wf.Write()
                wf.Close()
            }
        } catch e {
        }
    }

    Sleep, % frameDelayMs
}
return

SuccessMessage:
MsgBox, AHK connection is running
return
