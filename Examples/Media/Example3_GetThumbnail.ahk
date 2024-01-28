#Requires AutoHotkey v2
#include ..\..\Lib\Media.ahk
#include ImagePut.ahk ; Download here: https://github.com/iseahound/ImagePut

thumbnail := Media.GetCurrentSession().Thumbnail
ImagePutClipboard(thumbnail) ; Copies the thumbnail to the clipboard