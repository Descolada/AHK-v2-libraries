#include ..\Lib\RegExHotstring.ahk
#Requires AutoHotkey v2.0 

RegExHotstring.MouseReset := 0
; Can be used as normal hotstrings
RegExHotstring("::omg", "oh my god")

; Replace 'l1' with 'level 1', 'l2' with 'level 2' etc
RegExHotstring("::l(\d+)", "level $1")

; Type Unicode characters with '{U+1234}' (any four hexadecimal numbers)
RegExHotstring("::{U\+([0-9A-F]{4})}", "{U+$1}")

; Type 'input: ', then some word/letters/numbers, and press an end character to display the written string
RegExHotstring("::input: (\S+)", (Match, *) => ToolTip("You wrote: '" Match[1] "'"))

; Next hotstrings only work in Chrome-based windows
RegExHotstring.HotIf((*) => WinActive("ahk_class Chrome_WidgetWin_1"))
; Replace '@gc' with '@gmail.com' only if it is preceded by alphanumeric characters and/or periods
RegExHotstring(":*?:[\w.]+\K@gc", "@gmail.com")