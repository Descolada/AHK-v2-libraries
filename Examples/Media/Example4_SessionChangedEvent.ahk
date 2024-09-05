#Requires AutoHotkey v2
#include ..\..\Lib\Media.ahk

; Start a new session to capture an event (eg first start-stop Spotify, then Youtube)
handle := Media.AddCurrentSessionChangedEvent(CurrentSessionChangedEventHandler)
Persistent()

CurrentSessionChangedEventHandler(session, *) {
    MsgBox "Session changed!"
        . "`nSourceAppUserModelId: " Media.GetCurrentSession().SourceAppUserModelId
}

Esc::handle.Remove()