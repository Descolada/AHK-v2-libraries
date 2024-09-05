#Requires AutoHotkey v2
#include ..\..\Lib\Media.ahk

; Start/stop the current session media to capture an event
handle := Media.GetCurrentSession().AddPlaybackInfoChangedEvent(PlaybackInfoChangedEventHandler)
Persistent()

PlaybackInfoChangedEventHandler(session, *) {
    MsgBox "Playback info changed!"
        . "`nPlaybackStatus: " Media.PlaybackStatus[session.PlaybackStatus]
        . "`nPlaybackType: " Media.PlaybackType[session.PlaybackType]
}

Esc::handle.Remove()