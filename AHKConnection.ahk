if !FileExist("workspace")
{
    MsgBox, Put this file one folder above your exploit's workspace folder then run it again (your exploit folder)
    ExitApp
}

if !FileExist("workspace/Replayability+_AHK")
{
    FileCreateDir, workspace/Replayability+_AHK
    MsgBox, AHK folder has been added to workspace
}

if !FileExist("workspace/Replayability+_AHK/Request")
{
    writefile := FileOpen("workspace/Replayability+_AHK/Request", "w")
    writefile.Write()
    writefile.Close()
    MsgBox, Request file has been added to AHK folder
}

#Persistent
SetTimer, MainLoop, -1
SetTimer, SuccessMessage, -1

#Include %A_ScriptDir%\WebSocket.ahk
WS_URL := "ws://127.0.0.1:8080/ahk"

WriteRequestAtomic(path, text) {
    tmp := path ".tmp"
    fh := FileOpen(tmp, "w")
    if !IsObject(fh)
        return false
    fh.Write(text)
    fh.Close()
    FileMove, %tmp%, %path%, 1
    return true
}

OnWSMessage(payload) {
    reqPath := A_ScriptDir "\workspace\Replayability+_AHK\Request"
    IfNotExist, %A_ScriptDir%\workspace\Replayability+_AHK
        FileCreateDir, %A_ScriptDir%\workspace\Replayability+_AHK
    payload := Trim(payload)
    if (payload = "")
        return
    WriteRequestAtomic(reqPath, payload)
}

StartWebSocket() {
    global WS_URL
    try {
        ws := WebSocket(WS_URL, {
            open: (this) => (TrayTip, AHKConnection, "WebSocket connected", 2),
            message: (this, msg) => (OnWSMessage(msg)),
            data: (this, data, size) => (
                str := StrGet(data, size, "utf-8")
                OnWSMessage(str)
            ),
            close: (this, status, reason) => (TrayTip, AHKConnection, "WS closed: " . status, 2)
        }, true)
    } catch e {
        TrayTip, AHKConnection, "WS init failed: " . e.Message, 4
        ws := ""
    }
    return ws
}

try {
    ws_client := StartWebSocket()
} catch e {}

MainLoop:
Loop
{
    readfile := FileOpen("workspace/Replayability+_AHK/Request", "r")
    rawdata := readfile.Read()
    if (rawdata != "")
    {
        for i,v in StrSplit(rawdata, ",")
        {
            if (v == "u")
                Send, {WheelUp 1}
            if (v == "d")
                Send, {WheelDown 1}
        }
        writefile := FileOpen("workspace/Replayability+_AHK/Request", "w")
        writefile.Write()
        writefile.Close()
    }
    readfile.Close()
    sleep, 1000/144
}
return

SuccessMessage:
MsgBox, AHK connection is running
return
