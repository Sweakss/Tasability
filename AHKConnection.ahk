if !FileExist("workspace")
{
    MsgBox "Put this file one folder above your exploit's workspace folder then run it again (your exploit folder)"
    ExitApp
}

requestFile := "workspace/Replayability+_AHK/Request"
if !FileExist("workspace/Replayability+_AHK")
{
    FileCreateDir "workspace/Replayability+_AHK"
    MsgBox "Replayability+_AHK folder has been added to workspace"
}

if !FileExist(requestFile)
{
    File := FileOpen(requestFile, "w")
    File.Close()
    MsgBox "Request file has been added to Replayability+_AHK folder"
}

frameDelayMs := 1000.0 / 60.0
trackedKeys := ["W","A","S","D","Space","LeftShift"]

KeyToken := {}
KeyToken["W"] := "w"
KeyToken["A"] := "a"
KeyToken["S"] := "s"
KeyToken["D"] := "d"
KeyToken["Space"] := "Space"
KeyToken["LeftShift"] := "LShift"

prevState := {}
for key in trackedKeys
    prevState[key] := false

SetKeyDelay(-1, 0)

SuccessMessage() {
    MsgBox "AHK connection is running"
}

SendKeyAction(keyName, action) {
    global KeyToken
    token := KeyToken.HasKey(keyName) ? KeyToken[keyName] : keyName
    if (action = "down")
        Send "{" token " down}"
    else
        Send "{" token " up}"
}

TrimStr(s) {
    return RegExReplace(s, "^\s+|\s+$")
}

MainLoop() {
    global requestFile, frameDelayMs, trackedKeys, prevState

    Loop {
        raw := ""
        try {
            File := FileOpen(requestFile, "r")
            raw := File.Read()
            File.Close()
        } catch e {}

        if (raw != "") {
            for token in StrSplit(raw, ",") {
                token := TrimStr(token)
                if (token = "")
                    continue

                if (token = "u") {
                    Send "{WheelUp 1}"
                    continue
                }
                if (token = "d") {
                    Send "{WheelDown 1}"
                    continue
                }

                if RegExMatch(token, "^\s*([%w%p]+)_(down|up)\s*$", m) {
                    keyRaw := m[1]
                    action := m[2]
                    foundKey := ""
                    StringUpper keyCheck, keyRaw
                    for k in trackedKeys {
                        StringUpper kUp, k
                        if (keyCheck = kUp) {
                            foundKey := k
                            break
                        }
                    }
                    if (foundKey = "")
                        foundKey := keyRaw
                    SendKeyAction(foundKey, action)
                    if (foundKey != "" && prevState.HasKey(foundKey)) {
                        prevState[foundKey] := action = "down"
                    }
                    continue
                }

                if RegExMatch(token, "^\s*\[(.*)\]\s*$", m) {
                    inner := RegExReplace(m[1], ",", " ")
                    currentState := {}
                    for key in trackedKeys
                        currentState[key] := false

                    for part in StrSplit(inner, " ") {
                        part := TrimStr(part)
                        if (part = "")
                            continue
                        StringUpper pUp, part
                        for key in trackedKeys {
                            StringUpper kUp, key
                            if (pUp = kUp) {
                                currentState[key] := true
                                break
                            }
                        }
                    }

                    for key in trackedKeys {
                        if currentState[key] && !prevState[key] {
                            SendKeyAction(key, "down")
                            prevState[key] := true
                        }
                        if !currentState[key] && prevState[key] {
                            SendKeyAction(key, "up")
                            prevState[key] := false
                        }
                    }

                    Sleep frameDelayMs
                    continue
                }
            }

            try {
                File := FileOpen(requestFile, "w")
                File.Close()
            } catch e {}
        }

        Sleep frameDelayMs
    }
}

SetTimer MainLoop, -1
SetTimer SuccessMessage, -1
return
