#Requires AutoHotkey v2
#include ..\..\Lib\Media.ahk

session := Media.GetCurrentSession()

MsgBox "App with the current session: " session.SourceAppUserModelId
    . "`nPlayback state: " Media.PlaybackStatus[session.PlaybackStatus] 
    . "`nTitle: " session.Title
    . "`nArtist: " session.Artist
    . "`nPosition: " session.Position "s (duration: " session.EndTime "s)"

if (MsgBox(session.PlaybackStatus = Media.PlaybackStatus.Playing ? "Pause media?" : "Play media?",, 0x4) = "Yes") {
    if session.PlaybackStatus = Media.PlaybackStatus.Playing
        session.Pause()
    else
        session.Play()
}