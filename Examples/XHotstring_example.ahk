#include ..\Lib\XHotstring.ahk
#Requires AutoHotkey v2.0

; Can be used as normal hotstrings
XHotstring("::omg", "oh my god")

; Replace 'l1' with 'level 1', 'l2' with 'level 2' etc
XHotstring("::l(\d+)", "level $1")

; Type Unicode characters with '{U+1234}' (any four hexadecimal numbers)
XHotstring(":O:{U\+([0-9A-F]{4})}", "{U+$1}")

; Type 'input: ', then some word/letters/numbers, and press an end character to display the written string
XHotstring("::input: (\S+)", (Match, *) => (ToolTip("You wrote: '" Match[1] "'"), SetTimer(ToolTip, -3000)))

; Convert from between kg and lbs, or Celcius and Fahrenheit by typing for example "!conv 120kg to lbs "
XHotstring("::!conv (?<Number>[\d.]+)(?<Space>\s*)(?<Unit>\S+) to (?<TargetUnit>\S+)", ConvertUnit)

; Next hotstrings only work in Chrome-based windows
XHotstring.HotIf((*) => WinActive("ahk_class Chrome_WidgetWin_1"))
; Replace '@gc' with '@gmail.com' only if it is preceded by alphanumeric characters and/or periods
XHotstring(":*?:[\w.]+\K@gc", "@gmail.com")

; Stop or resume the hotstring recognizer by pressing End key
End::(XHotstring.IsActive) ? XHotstring.Stop() : XHotstring.Start()

ConvertUnit(Match, EndChar, *) {
    switch Match["Unit"], 0 {
        case "kg":
            if Match["TargetUnit"] = "lbs" || Match["TargetUnit"] = "lb"
                Converted := Round(Float(Match["Number"]) * 2.20462)
        case "lbs", "lb":
            if Match["TargetUnit"] = "kg"
                Converted := Round(Float(Match["Number"]) / 2.20462)
        case "C", "°C":
            if InStr(Match["TargetUnit"], "F")
                Converted := Round((Float(Match["Number"]) * 9 / 5) + 32)
        case "F", "°F":
            if InStr(Match["TargetUnit"], "C")
                Converted := Round((Float(Match["Number"]) - 32) * 5 / 9)
    }
    if IsSet(Converted)
        Send Converted Match["Space"] Match["TargetUnit"] EndChar
    else
        MsgBox "No conversion between " Match["Unit"] " and " Match["TargetUnit"] " possible"
}