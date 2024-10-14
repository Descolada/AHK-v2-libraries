#Requires AutoHotkey v2
/**
 * Implements the `Hotstring` function but for regular expression trigger-words and replacements. 
 * 
 * `XHotstring(String [, Replacement, OnOffToggle, SendFunction])`
 *  > See documentation for `Hotstring`. Only the `K` option is currently not supported.
 *  > SendFunction can optionally be set to use a custom function to send the text (eg via Clipboard)
 * 
 * `XHotstring(NewOptions)`
 * 
 * `XHotstring(SubFunction [, Value1])`
 * 
 * `XHotstring.HotIf(Callback := "")`
 *  > Sets a new HotIf context for the next registered hotstrings
 * 
 * `XHotstring.Delete(Trigger)`
 *  > Removes a XHotstring completely. This differs from OnOffToggle because OnOffToggle does
 *    not delete the hotstring, only temporarily enables/disables it. 
 * 
 * `XHotstring.Start()`
 *  > Resumes the hotstring recognizer after being stopped with `XHotstring.Stop()`.
 * 
 * `XHotstring.Stop()`
 *  > Stops the hotstring recognizer.
 * 
 * `XHotstring.Reset()`
 *  > Immediately resets the hotstring recognizer content.
 * 
 * `XHotstring.HotstringRecognizer`
 *  > Current XHotstring recognizer content.
 * 
 * `XHotstring.IsActive`
 *  > Whether the XHotstring is currently gathering input and active.
 * 
 * `XHotstring.EndChars`
 *  > List of keys that, when pressed, may trigger a XHotstring. 
 *    Default is ``-()[]{}':;`"/\,.?!`n`s`t``
 * 
 * `XHotstring.ResetKeys`
 *  > List of keys that, when pressed, will reset the XHotstring recognizer content.
 *    Default is `{Left}{Right}{Up}{Down}{Next}{Prior}{Home}{End}`
 * 
 * `XHotstring.MouseReset`
 *  > Controls whether a mouse button click resets the recognizer or not. By default this is On.
 * 
 * `XHotstring.SendFunction`
 *  > Can be used to change the default Send function for all new XHotstrings. Eg. `XHotstring.SendFunction := SendEvent`
 *    Default is `Send`
 */
class XHotstring {
    static HotstringRecognizer := "", IsActive := 0, __EndChars := "-()[]{}':;`"/\,.?!`n`s`t", SendFunction := Send
        , __DefaultOptions := Map(), __ResetKeys := "{Left}{Right}{Up}{Down}{Next}{Prior}{Home}{End}"
        , __CurrentHotIf := "", __RegisteredHotstrings := [], __HotstringsReadyToTrigger := []
        , __MouseReset := 1, __hWnd := DllCall("GetForegroundWindow", "ptr"), __Hook := 0
        , __ActiveEndChars := "", __ActiveNoModifierEndChars := "", __ActiveModifierEndChars := ""
        , __SpecialChars := "^+!#{}", __ShiftPressed := 0
    /**
     * Registers or modifies a XHotstring. See documentation for `Hotstring` for more information.
     * @param {String} Trigger Either a trigger string in the format `:options:trigger`, or NewOptions that
     *  sets new options for all new XHotstrings, or SubFunction ("MouseReset", "Reset", or "EndChars")
     * 
     *  Options (follow with a zero to turn them off):
     *  > `M0` (M followed by a zero): Turn off replacing RegEx back-references in the replacement word.
     *  > `*` (asterisk): An ending character is not required to trigger the hotstring.
     *  > `?` (question mark): The hotstring will be triggered even when it is inside another word.
     *      NOTE: If this is *not* used then the trigger RegEx will be modified to be "(?<=\s|^)TRIGGER$".
     *  > `B0` (B followed by a zero): Automatic backspacing is not done to erase the abbreviation you type.
     *  > `C`: Case sensitive: When you type an abbreviation, it must exactly match the case defined in the script.
     *      NOTE: If this is used and the RegEx trigger options does not contain `i`, then the `i` will be added. 
     *            If this is *not* used then `i` will be removed from the options.
     *  > `C1` (C followed by a one): Turn off case conform, meaning the replacement case will not match the trigger case.
     *  > `O`: Omit the ending character of auto-replace hotstrings when the replacement is produced.
     *  > `T`: Send the replacement string in Text mode, meaning special characters such as `+` are typed out literally.
     *  > `R`: Send the replacement string in Raw mode.
     *  > `SI`, `SE`, `SP`: Use SendInput, SendEvent, or SendPlay to send the replacement string.
     *  > `Z`: Reset the hotstring recognizer after each replacement.
     *      
     * @param {String | Func} Replacement The replacement string or a callback function. The replacement string can contain RegEx
     *  match groups (see `RegExReplace` for more information). 
     *  The callback function `Callback(TriggerMatch, EndChar, HS)` will receive a RegExMatch object
     *  TriggerMatch, the ending character, and a XHotstring object containing information about the
     *  XHotstring that matched.
     * @param {String | 'On' | 'Off' | 'Toggle'} OnOffToggle 
     * @param {Func} SendFunction The Send function to use for sending the replacement. Default is `Send`.
     * @returns {Object} The hotstring object {Trigger, UnmodifiedTrigger, TriggerWithOptions, Replacement, HotIf, SendFunction, Options, Active}
     *  Where Trigger is the RegEx trigger actually used for matching (this might be a modified version eg for case-sensitivity),
     *  UnmodifiedTrigger is the original version, Options is a Map of all the options values (this shouldn't be modified manually). 
     */
    static Call(Trigger, Replacement?, OnOffToggle?, SendFunction?) {
        if !this.__RegisteredHotstrings.Length
            this.Start()
        if !RegExMatch(Trigger, "^:([^:]*):", &Options:="") {
            if Trigger = "MouseReset" || (Trigger := "NoMouse" && !(Replacement := 0))
                return (Prev := this.MouseReset, this.MouseReset := Replacement ?? Prev, Prev)
            else if Trigger = "Reset"
                return this.Reset()
            else if Trigger = "EndChars"
                return (Prev := this.EndChars, this.EndChars := Replacement ?? Prev, Prev)

            return (Prev := this.__OptionsToString(this.__DefaultOptions), this.__ParseOptions(this.__DefaultOptions, Trigger), Prev)
        }
        TriggerWithOptions := Trigger, Options := Options[1], Trigger := RegExReplace(Trigger, "^:([^:]*):",,, 1)
        if Trigger = ""
            throw ValueError("Invalid XHotstring trigger", -1, "Can't be an empty string")
        for HS in this.__RegisteredHotstrings {
            if HS.TriggerWithOptions == TriggerWithOptions && HS.HotIf == this.__CurrentHotIf {
                if IsSet(Replacement)
                    HS.Replacement := Replacement
                if IsSet(Options)
                    this.__ParseOptions(HS.Options, Options, HS)
                if IsSet(OnOffToggle)
                    HS.Active := (OnOffToggle = "On" || OnOffToggle = 1) ? 1 : (OnOffToggle = "Off" || OnOffToggle = 0) ? 0 : (OnOffToggle = "Toggle" || OnOffToggle = -1) ? !HS.Active : MsgBox("Invalid OnOffOptions", "Error")
                if IsSet(SendFunction)
                    HS.SendFunction := SendFunction
                return HS
            }
        }
        if !IsSet(Replacement)
            throw ValueError("No such XHotstring registered", -1, Trigger)

        opts := this.__DefaultOptions.Clone()
        this.__RegisteredHotstrings.Push(HS := {TriggerWithOptions:TriggerWithOptions, Trigger:Trigger, UnmodifiedTrigger:Trigger, Replacement:Replacement, HotIf:this.__CurrentHotIf, SendFunction:SendFunction ?? this.SendFunction, Options:opts, Active:1})
        this.__ParseOptions(opts, Options, HS)
        if HasMethod(Replacement)
            opts["X"] := 1
        return HS
    }
    ; Deletes the specified hotstring
    static Delete(Trigger) {
        for HS in this.__RegisteredHotstrings {
            if HS.TriggerWithOptions == Trigger && HS.HotIf == this.__CurrentHotIf {
                this.__RegisteredHotstrings.Delete(HS)
                if !this.__RegisteredHotstrings.Count
                    this.Stop()
                return
            }
        }
        throw ValueError("No such XHotstring registered", -1, Trigger)
    }
    /**
     * Sets a new HotIf callback and returns the previous one
     * @param {Func} Callback 
     * @returns {String | Func}
     */
    static HotIf(Callback := "") {
        LastHotIf := this.__CurrentHotIf
        this.__CurrentHotIf := Callback
        return LastHotIf
    }
    ; Gets or sets the new MouseReset value
    static MouseReset {
        get => this.__MouseReset
        set => (this.__SetMouseReset(Value), this.__MouseReset := !!Value)
    }
    ; Gets or sets new end-characters. This affects all registered XHotstrings
    static EndChars {
        get => this.__EndChars
        set {
            static lpKeyState := Buffer(256,0), pwszBuff := Buffer(4)
            if !(Value is String) || Value = ""
                throw ValueError("Invalid EndChars", -1)
            this.__EndChars := Value
            this.__NoModifierEndChars := ""
            this.__ModifierEndChars := InStr(Value, " ") ? " " : ""
            if InStr(Value, "`n")
                Value .= "`r"
            NumPut("char", 0, lpKeyState, 0x10)
            Loop parse Value {
                if (len := DllCall("ToUnicode", "uint", VK := GetKeyVK(A_LoopField), "uint", SC := GetKeySC(A_LoopField), "ptr", lpKeyState, "ptr", pwszBuff, "int", pwszBuff.size, "uint", 0)) <= 0
                    continue
                if StrGet(pwszBuff, len, "UTF-16") == A_LoopField
                    this.__NoModifierEndChars .= "{" A_LoopField "}"
            }
            NumPut("char", 0x80, lpKeyState, 0x10)
            Loop parse Value {
                if (len := DllCall("ToUnicode", "uint", VK := GetKeyVK(A_LoopField), "uint", SC := GetKeySC(A_LoopField), "ptr", lpKeyState, "ptr", pwszBuff, "int", pwszBuff.size, "uint", 0)) <= 0
                    continue
                if StrGet(pwszBuff, len, "UTF-16") == A_LoopField
                    this.__ModifierEndChars .= "{" A_LoopField "}"
            }
        }
    }
    ; Can be used to resume the hotstring recognizer after stopping it with `XHotstring.Stop()`
    static Start() {
        if this.IsActive
            return
        this.Reset()
        this.MouseReset := this.MouseReset
        this.EndChars := this.EndChars
        this.__Hook.Start()
        this.IsActive := 1
    }
    ; Stops the hotstring recognizer
    static Stop() {
        this.IsActive := 0
        this.__SetMouseReset(0)
        this.__Hook.Stop()
    }
    ; Immediately resets the hotstring recognizer
    static Reset(*) => (this.__DeactivateEndChars(), this.HotstringRecognizer := "", this.__hWnd := DllCall("GetForegroundWindow", "ptr"))

    ; ONLY INTERNAL METHODS AHEAD

    static __New() {
        this.Prototype.__Static := this
        this.__Hook := InputHook("V L0 I" A_SendLevel)
        this.__Hook.KeyOpt(this.__ResetKeys "{Backspace}", "N")
        this.__Hook.OnKeyDown := this.__OnKeyDown.Bind(this)
        this.__Hook.OnKeyUp := this.__OnKeyUp.Bind(this)
        this.__Hook.OnChar := this.__AddChar.Bind(this)
        ; These two throw critical recursion errors if defined with the normal syntax and AHK is ran in debugging mode
        this.DefineProp("MinSendLevel", {
            set:((hook, this, value, *) => hook.MinSendLevel := value).Bind(this.__Hook), 
            get:((hook, *) => hook.MinSendLevel).Bind(this.__Hook)})
        this.DefineProp("ResetKeys", {
            set:((this, dummy, value, *) => (this.__Hook.KeyOpt(this.__ResetKeys, "-N"), this.__ResetKeys := value, this.__Hook.KeyOpt(this.__ResetKeys, "N"), Value)).Bind(this), 
            get:((this, *) => this.__ResetKeys).Bind(this)})
        this.__DefaultOptions.CaseSense := 0
        this.__DefaultOptions.Set("*", 0, "?", 0, "B", 1, "C", 0, "O", 0, "T", 0, "R", 0, "S", 0, "M", 1, "X", 0, "Z", 0)
    }
    static __AddChar(ih, char) {
        Critical
        hWnd := DllCall("GetForegroundWindow", "ptr")
        if char && InStr(this.EndChars, char) {
            if hWnd != this.__hWnd {
                if InStr(this.__ActiveEndChars, char) ; This was blocked, so resend it
                    Send "{Blind}" char
            } else {
                for Active in this.__HotstringsReadyToTrigger {
                    if Active.HS.HotIf = "" || Active.HS.HotIf.Call(Active.HS, Active.TriggerMatch)
                        return this.__TriggerHS(Active.HS, Active.TriggerMatch, Active.Replacement, char)
                }
            }
        }
        this.__DeactivateEndChars()
        if this.__hWnd != hWnd
            this.__hWnd := hWnd, this.HotstringRecognizer := ""
        if char = "" {
            this.HotstringRecognizer := RegExReplace(this.HotstringRecognizer, "s)\X$",,, 1)
        } else {
            this.HotstringRecognizer .= char
            if StrLen(this.HotstringRecognizer) > 100
                this.HotstringRecognizer := SubStr(this.HotstringRecognizer, -50)
        }

        for HS in this.__RegisteredHotstrings {
            if HS.Active && (Pos := RegExMatch(this.HotstringRecognizer, HS.Trigger, &Match:="")) && Match[] {
                Replacement := HS.Options["M"] && !HS.Options["X"] ? SubStr(RegExReplace(this.HotstringRecognizer, HS.Trigger, HS.Replacement,,1), Pos) : HS.Replacement
                if HS.Options["*"] && (HS.HotIf = "" || HS.HotIf.Call(HS, Match)) { 
                    return this.__TriggerHS(HS, Match, Replacement, "")
                } else {
                    this.__ActivateEndChars(HS, Match, Replacement)
                }
            }
        }
    }
    static __OnKeyDown(ih, vk, sc) {
        Critical
        if vk = 8
            this.__AddChar(ih, "")
        else {
            if (vk = 0xA0 || vk = 0xA1 || vk == 0x10) { ; Shift is pressed
                this.__ShiftPressed := 1
                if this.__ActiveNoModifierEndChars 
                    this.__Hook.KeyOpt(this.__ActiveNoModifierEndChars, "-S")
                if this.__ActiveEndChars
                    this.__Hook.KeyOpt(this.__ActiveEndChars, "+S")
            } else
                this.Reset()
        }
    }
    static __OnKeyUp(ih, vk, sc) {
        Critical
        if (vk = 0xA0 || vk = 0xA1 || vk == 0x10) { ; Shift is released
            this.__ShiftPressed := 0
            if this.__ActiveEndChars
                this.__Hook.KeyOpt(this.__ActiveEndChars, "-S")
            if this.__ActiveNoModifierEndChars
                this.__Hook.KeyOpt(this.__ActiveNoModifierEndChars, "+S")
        }
    }
    static __ParseOptions(OptObj, OptStr, HS?) {
        Loop parse OptStr {
            switch A_LoopField, 0 {
                case "0":
                    OptObj[last] := 0
                case "1":
                    if last = "C"
                        OptObj["C"] := 2
                case "E", "I", "P":
                    if last = "S" {
                        OptObj["S"] := A_LoopField
                    } else
                        throw ValueError("Invalid Option", -1, A_LoopField)
                case "*", "?", "B", "C", "O", "T", "R", "M", "Z":
                    OptObj[A_LoopField] := 1
                case " ", "`t", "S":
                    continue
                default:
                    throw ValueError("Invalid Option", -1, A_LoopField)
            }
            last := A_LoopField
        }
        if IsSet(HS) {
            HS.SendFunction := OptObj["S"] = "I" ? SendInput : OptObj["S"] = "E" ? SendEvent : OptObj["S"] = "P" ? SendPlay : HS.SendFunction
            HS.Trigger := HS.UnmodifiedTrigger
            RegExOptsExist := RegExMatch(HS.Trigger, "^([^(\\]+)\)", &RegExOpts:="")
            if OptObj["C"] != 1 && !RegExOptsExist {
                HS.Trigger := "i)" HS.Trigger
            }
            if SubStr(HS.Trigger, 1, 1) = ")"
                HS.Trigger := SubStr(HS.Trigger, 2)
            if !OptObj["?"]
                HS.Trigger := RegExReplace(HS.Trigger, "^([^(\\]+\))?", "$1(?<=\s|^)",, 1) "$"
        }
    }
    static __OptionsToString(OptObj) {
        OptStr := ""
        for k, v in OptObj {
            if k == "X"
                continue
            else if k == "C"
                OptStr .= k (v == 2 ? "1" : v == 1 ? "" : "0")
            else
                OptStr .= k (v == 1 ? "" : v)
        }
        return OptStr
    }
    static __ActivateEndChars(HS, TriggerMatch, Replacement) {
        static lpKeyState := Buffer(256, 0)
        if this.__ActiveEndChars
            return
        this.__HotstringsReadyToTrigger.Push({HS:HS, TriggerMatch:TriggerMatch, Replacement:Replacement})
        this.__ActiveEndChars := this.__EndChars
        this.__ActiveNoModifierEndChars := this.__NoModifierEndChars
        this.__ActiveModifierEndChars := this.__ModifierEndChars
        ShiftState := GetKeyState("Shift")
        if this.__ActiveModifierEndChars {
            if ShiftState
                this.__Hook.KeyOpt(this.__ActiveModifierEndChars, "+S")
            this.__Hook.KeyOpt("{Shift}{LShift}{RShift}", "+N")
        }
        if this.__ActiveNoModifierEndChars && !ShiftState
            this.__Hook.KeyOpt(this.__ActiveNoModifierEndChars, "+S")
    }
    static __DeactivateEndChars() {
        if this.__ActiveEndChars = ""
            return
        this.__HotstringsReadyToTrigger := []
        if this.__ActiveNoModifierEndChars
            this.__Hook.KeyOpt(this.__ActiveNoModifierEndChars, "-S")
        if this.__ActiveModifierEndChars
            this.__Hook.KeyOpt(this.__ActiveModifierEndChars, "-S")
        this.__Hook.KeyOpt("{Shift}{LShift}{RShift}", "-N")
        this.__ActiveEndChars := ""
    }
    static __TriggerHS(HS, TriggerMatch, Replacement, EndChar, *) {
        Critical 
        local opts := HS.Options, TriggerText := TriggerMatch[], BS := 0, B := opts["B"]
        this.__DeactivateEndChars()

        if opts["X"] {
            replacement := "", TextMode := ""
            if B
                RegExReplace(TriggerText, "s)\X",, &BS)
        } else {
            if (opts["C"] < 2) && IsUpper(SubStr(ThisHotstringLetters := RegexReplace(TriggerText, "\P{L}"), 1, 1), 'Locale') {
                if IsUpper(trail := SubStr(ThisHotstringLetters, 2), 'Locale')
                    replacement := StrUpper(replacement)
                else
                    replacement := StrUpper(SubStr(replacement, 1, 1)) (IsLower(trail, 'Locale') ? StrLower(SubStr(replacement, 2)) : replacement)
            }
            TextMode := opts["T"] ? "{Text}" : opts["R"] ? "{Raw}" : ""
            if B {
                RegExReplace(TriggerText, "s)\X",, &MaxBS:=0)
                BoundGraphemeCallout := GraphemeCallout.Bind(info := {CompareString: replacement, GraphemeLength:0, Pos:1})
                RegExMatch(TriggerText, "s)(?:\X)(?CBoundGraphemeCallout)")
                if !TextMode && info.GraphemeLength && (SpecialChar := RegExMatch(TriggerText, "[\Q" this.__SpecialChars "\E]")) && SpecialChar < info.Pos {
                    RegExReplace(SubStr(TriggerText, 1, SpecialChar), "s)\X",, &Diff:=0)
                    BS := MaxBS - Diff + 1, replacement := SubStr(replacement, SpecialChar)
                } else {
                    BS := MaxBS - info.GraphemeLength, replacement := SubStr(replacement, info.Pos)
                }
            }
        }

        Omit := opts["O"] || (opts["X"] && B)

        if (str := (B ? "{BS " BS "}" : "") TextMode replacement (Omit ? "" : (TextMode ? EndChar : "{Raw}" EndChar)))
            HS.SendFunction.Call(str)

        if B || opts["Z"]
            this.HotstringRecognizer := ""
        if !Omit
            this.HotstringRecognizer .= EndChar

        Critical 'Off'
        if opts["X"]
            HS.Replacement.Call(TriggerMatch, EndChar, HS)

        GraphemeCallout(info, m, *) => SubStr(info.CompareString, info.Pos, len := StrLen(m[0])) == m[0] ? (info.Pos += len, info.GraphemeLength++, 1) : -1
    }

    static __SetMouseReset(NewValue) {
        static MouseRIProc := this.__MouseRawInputProc.Bind(this), DevSize := 8 + A_PtrSize, RIDEV_INPUTSINK := 0x00000100
        , RIDEV_REMOVE := 0x00000001, RAWINPUTDEVICE := Buffer(DevSize, 0), Active := 0, g := Gui()
        if !!NewValue = Active
            return
        if Active := !!NewValue {
            ; Register mouse for WM_INPUT messages.
            NumPut("UShort", 1, "UShort", 2, "Uint", RIDEV_INPUTSINK, "Ptr", g.hWnd, RAWINPUTDEVICE)
            DllCall("RegisterRawInputDevices", "Ptr", RAWINPUTDEVICE, "UInt", 1, "UInt", DevSize)
            OnMessage(0x00FF, MouseRIProc)
        } else {
            OnMessage(0x00FF, MouseRIProc, 0)
            NumPut("Uint", RIDEV_REMOVE, RAWINPUTDEVICE, 4)
            DllCall("RegisterRawInputDevices", "Ptr", RAWINPUTDEVICE, "UInt", 1, "UInt", DevSize)
        }
    }

    static __MouseRawInputProc(wParam, lParam, *) {
        ; RawInput statics
        static DeviceSize := 2 * A_PtrSize, iSize := 0, sz := 0, pcbSize:=8+2*A_PtrSize, offsets := {usButtonFlags: (12+2*A_PtrSize), x: (20+A_PtrSize*2), y: (24+A_PtrSize*2)}, uRawInput
        ; Get hDevice from RAWINPUTHEADER to identify which mouse this data came from
        header := Buffer(pcbSize, 0)
        If !DllCall("GetRawInputData", "UPtr", lParam, "uint", 0x10000005, "Ptr", header, "Uint*", &pcbSize, "Uint", pcbSize)
            return 0
        ThisMouse := NumGet(header, 8, "UPtr")
        ; Find size of rawinput data - only needs to be run the first time.
        if (!iSize) {
            r := DllCall("GetRawInputData", "UInt", lParam, "UInt", 0x10000003, "Ptr", 0, "UInt*", &iSize, "UInt", 8 + (A_PtrSize * 2))
            uRawInput := Buffer(iSize, 0)
        }
        ; Get RawInput data
        r := DllCall("GetRawInputData", "UInt", lParam, "UInt", 0x10000003, "Ptr", uRawInput, "UInt*", &sz := iSize, "UInt", 8 + (A_PtrSize * 2))
        Loop {
            usButtonFlags := NumGet(uRawInput, offsets.usButtonFlags, "ushort")
            if usButtonFlags & 0x0001 || usButtonFlags & 0x0004 || usButtonFlags & 0x0010 || usButtonFlags & 0x0040 || usButtonFlags & 0x0100 {
                this.__DeactivateEndChars(), this.HotstringRecognizer := "", MouseGetPos(,, &hWnd), this.__hWnd := hWnd
                While DllCall("GetRawInputBuffer", "Ptr", uRawInput, "Uint*", &sz := iSize, "UInt", 8 + (A_PtrSize * 2))
                    continue
            }
        } Until !DllCall("GetRawInputBuffer", "Ptr", uRawInput, "Uint*", &sz := iSize, "UInt", 8 + (A_PtrSize * 2))
    }
}