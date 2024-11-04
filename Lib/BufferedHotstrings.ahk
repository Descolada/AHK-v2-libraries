#requires AutoHotkey v2.0.14
/**
 * Sends a hotstring and buffers user keyboard input while sending, which means keystrokes won't
 * become interspersed or get lost. This requires that the hotstring has the X (execute) and B0 (no
 * backspacing) options enabled: these can be globally enabled with `#Hotstring XB0`
 * Note that mouse clicks *will* interrupt sending keystrokes.
 * @param replacement The hotstring to be sent. If no hotstring is provided then instead _HS options
 * will be modified according to the provided opts. 
 * @param opts Optional: hotstring options that will either affect all the subsequent _HS calls (if 
 * no replacement string was provided), or can be used to disable backspacing (`:B0:hs::hotstring` should 
 * NOT be used, correct is `_HS("hotstring", "B0")`). 
 * Additionally, differing from the default AHK hotstring syntax, the default option of backspacing
 * deletes only the non-matching end of the trigger string (compared to the replacement string).
 * Use the `BF` option to delete the whole trigger string. 
 * Also, using `Bn` backspaces only n characters and `B-n` leaves n characters from the beginning 
 * of the trigger string.
 * 
 * * Hotstring settings that modify the hotstring recognizer (eg Z, EndChars) must be changed with `#Hotstring`
 * * Hotstring settings that modify SendMode or speed must be changed with `_HS(, "opts")` or with hotstring
 *  local options such as `:K40:hs::hotstring`. In this case `#Hotstring` has no effect.
 * * O (omit EndChar) argument default option needs to be changed with `_HS(, "O")` AND with `#Hotstring O`.
 * 
 * Note that if changing global settings then the SendMode will be reset to InputThenEvent if no SendMode is provided.
 * SendMode can only be changed with this (`#Hotstring SE` has no effect).
 * @param sendFunc Optional: this can be used to define a default custom send function (if replacement
 * is left empty), or temporarily use a custom function. This could, for example, be used to send
 * via the Clipboard. This only affects sending the replacement text: backspacing and sending the 
 * ending character is still done with the normal Send function.
 * @returns {void} 
 */
_HS(replacement?, opts?, sendFunc?) {
    static HSInputBuffer := InputBuffer(), DefaultOmit := false, DefaultSendMode := A_SendMode, DefaultKeyDelay := 0
        , DefaultTextMode := "", DefaultBS := 0xFFFFFFF0, DefaultCustomSendFunc := "", DefaultCaseConform := true
        , __Init := HotstringRecognizer.Start()
    ; Save global variables ASAP to avoid these being modified if _HS is interrupted
    local Omit, TextMode, PrevKeyDelay := A_KeyDelay, PrevKeyDurationPlay := A_KeyDurationPlay, PrevSendMode := A_SendMode
        , ThisHotkey := A_ThisHotkey, EndChar := A_EndChar, Trigger := RegExReplace(ThisHotkey, "^:[^:]*:",,,1)
        , ThisHotstring := SubStr(HotstringRecognizer.Content, -StrLen(Trigger)-StrLen(EndChar))

    ; Only options without replacement text changes the global/default options
    if !IsSet(replacement) {
        if IsSet(sendFunc)
            DefaultCustomSendFunc := sendFunc
        if IsSet(opts) {
            i := 1, opts := StrReplace(opts, " "), len := StrLen(opts)
            While i <= len {
                o := SubStr(opts, i, 1), o_next := SubStr(opts, i+1, 1)
                if o = "S" {
                    ; SendMode is reset if no SendMode is specifically provided
                    DefaultSendMode := o_next = "E" ? "Event" : o_next = "I" ? "InputThenPlay" : o_next = "P" ? "Play" : (i--, "Input")
                    i += 2
                    continue
                } else if o = "O"
                    DefaultOmit := o_next != "0"
                else if o = "*"
                    DefaultOmit := o_next != "0"
                else if o = "K" && RegExMatch(opts, "i)^[-0-9]+", &KeyDelay, i+1) {
                    i += StrLen(KeyDelay[0]) + 1, DefaultKeyDelay := Integer(KeyDelay[0])
                    continue
                } else if o = "T"
                    DefaultTextMode := o_next = "0" ? "" : "{Text}"
                else if o = "R"
                    DefaultTextMode := o_next = "0" ? "" : "{Raw}"
                else if o = "B" {
                    ++i, DefaultBS := RegExMatch(opts, "i)^[fF]|^[-0-9]+", &BSCount, i) ? (i += StrLen(BSCount[0]), BSCount[0] = "f" ? 0xFFFFFFFF : Integer(BSCount[0])) : 0xFFFFFFF0
                    continue
                } else if o = "C"
                    DefaultCaseConform := o_next = "0" ? 1 : 0
                i += IsNumber(o_next) ? 2 : 1
            }
        }
        return
    }
    if !IsSet(replacement)
        return
    ; Musn't use Critical here, otherwise InputBuffer callbacks won't work
    ; Start capturing input for the rare case where keys are sent during options parsing
    HSInputBuffer.Start()

    TextMode := DefaultTextMode, BS := DefaultBS, Omit := DefaultOmit, CustomSendFunc := sendFunc ?? DefaultCustomSendFunc, CaseConform := DefaultCaseConform
    SendMode DefaultSendMode
    if InStr(DefaultSendMode, "Play")
        SetKeyDelay , DefaultKeyDelay, "Play"
    else
        SetKeyDelay DefaultKeyDelay

    ; The only opts currently accepted is "B" or "B0" to enable/disable backspacing, since this can't 
    ; be changed with local hotstring options
    if IsSet(opts) && InStr(opts, "B")
        BS := RegExMatch(opts, "i)[fF]|[-0-9]+", &BSCount) ? (BSCount[0] = "f" ? 0xFFFFFFFF : Integer(BSCount[0])) : 0xFFFFFFF0
    ; Load local hotstring options, but don't check for backspacing
    if RegExMatch(ThisHotkey, "^:([^:]+):", &opts) { 
        opts := StrReplace(opts[1], " "), i := 1, len := StrLen(opts)
        While i <= len {
            o := SubStr(opts, i, 1), o_next := SubStr(opts, i+1, 1)
            if o = "S" {
                SendMode(o_next = "E" ? "Event" : o_next = "I" ? "InputThenPlay" : o_next = "P" ? "Play" : "Input")
                i += 2
                continue
            } else if o = "O"
                Omit := o_next != "0"
            else if o = "*"
                Omit := o_next != "0"
            else if o = "K" && RegExMatch(opts, "[-0-9]+", &KeyDelay, i+1) {
                i += StrLen(KeyDelay[0]) + 1, KeyDelay := Integer(KeyDelay[0])
                if InStr(A_SendMode, "Play")
                    SetKeyDelay , KeyDelay, "Play"
                else
                    SetKeyDelay KeyDelay
                continue
            } else if o = "T"
                TextMode := o_next = "0" ? "" : "{Text}"
            else if o = "R"
                TextMode := o_next = "0" ? "" : "{Raw}"
            else if o = "C"
                CaseConform := o_next = "0" ? 1 : 0
            i += IsNumber(o_next) ? 2 : 1
        }
    }

    if CaseConform && ThisHotstring && IsUpper(SubStr(ThisHotstringLetters := RegexReplace(ThisHotstring, "\P{L}"), 1, 1), 'Locale') {
        if IsUpper(SubStr(ThisHotstringLetters, 2), 'Locale')
            replacement := StrUpper(replacement), Trigger := StrUpper(Trigger)
        else
            replacement := (BS < 0xFFFFFFF0 ? replacement : StrUpper(SubStr(replacement, 1, 1))) SubStr(replacement, 2), Trigger := StrUpper(SubStr(Trigger, 1, 1)) SubStr(Trigger, 2)
    }

    ; If backspacing is enabled, get the activation string length using Unicode character length 
    ; since graphemes need one backspace to be deleted but regular StrLen would report more than one
    if BS {
        RegExReplace(Trigger, "s)((?>\P{M}(\p{M}|\x{200D}))+\P{M})|\X", "_", &MaxBS:=0)
        if BS = 0xFFFFFFF0 {
            BoundGraphemeCallout := GraphemeCallout.Bind(info := {CompareString: replacement, GraphemeLength:0, Pos:1})
            RegExMatch(Trigger, "s)((?:(?>\P{M}(\p{M}|\x{200D}))+\P{M})|\X)(?CBoundGraphemeCallout)")
            if !TextMode && info.GraphemeLength && (SpecialChar := RegExMatch(Trigger, "[\Q^+!#{}\E]")) && SpecialChar < info.Pos {
                RegExReplace(SubStr(Trigger, 1, SpecialChar), "s)\X",, &Diff:=0)
                BS := MaxBS - Diff + 1, replacement := SubStr(replacement, SpecialChar)
            } else {
                BS := MaxBS - info.GraphemeLength, replacement := SubStr(replacement, info.Pos)
            }
        } else
            BS := BS = 0xFFFFFFFF ? MaxBS : BS > 0 ? BS : MaxBS + BS
    }
    ; Send backspacing + TextMode + replacement string + optionally EndChar. SendLevel isn't changed
    ; because AFAIK normal hotstrings don't add the replacements to the end of the hotstring recognizer
    if TextMode || !CustomSendFunc
        Send((BS ? "{BS " BS "}" : "") TextMode replacement (Omit ? "" : (TextMode ? EndChar : "{Raw}" EndChar)))
    else {
        Send((BS ? "{BS " BS "}" : ""))
        CustomSendFunc(replacement)
        if !Omit ; This could also be send with CustomSendFunc, but some programs (eg Chrome) sometimes trim spaces/tabs
            Send("{Raw}" EndChar)
    }
    ; Reset the recognizer, so the next step will be captured by it
    HotstringRecognizer.Reset()
    ; Release the buffer, but restore Send settings *after* it (since it also uses Send)
    HSInputBuffer.Stop()
    if InStr(A_SendMode, "Play")
        SetKeyDelay , PrevKeyDurationPlay, "Play"
    else
        SetKeyDelay PrevKeyDelay
    SendMode PrevSendMode

    GraphemeCallout(info, m, *) => SubStr(info.CompareString, info.Pos, len := StrLen(m[0])) == m[0] ? (info.Pos += len, info.GraphemeLength++, 1) : -1
}

/**
 * Mimics the internal hotstring recognizer as close as possible. It is *not* automatically
 * cleared if a hotstring is activated, as AutoHotkey doesn't provide a way to do that. 
 * 
 * Properties:
 * HotstringRecognizer.Content  => the current content of the recognizer
 * HotstringRecognizer.Length   => length of the content string
 * HotstringRecognizer.IsActive => whether HotstringRecognizer is active or not
 * HotstringRecognizer.MinSendLevel => minimum SendLevel that gets captured
 * HotstringRecognizer.ResetKeys    => gets or sets the keys that reset the recognizer (by default the arrow keys, Home, End, Next, Prior)
 * HotstringRecognizer.OnChange     => can be set to a callback function that is called when the recognizer content changes.
 *      The callback receives two arguments: Callback(OldContent, NewContent)
 * 
 * Methods:
 * HotstringRecognizer.Start()  => starts capturing hotstring content
 * HotstringRecognizer.Stop()   => stops capturing
 * HotstringRecognizer.Reset()  => clears the content and resets the internal foreground window
 * 
 */
class HotstringRecognizer {
    static Content := "", Length := 0, IsActive := 0, OnChange := 0, __ResetKeys := "{Left}{Right}{Up}{Down}{Next}{Prior}{Home}{End}"
        , __hWnd := DllCall("GetForegroundWindow", "ptr"), __Hook := 0

    static __New() {
        this.__Hook := InputHook("V L0 I" A_SendLevel)
        this.__Hook.KeyOpt(this.__ResetKeys "{Backspace}", "N")
        this.__Hook.OnKeyDown := this.Reset.Bind(this)
        this.__Hook.OnChar := this.__AddChar.Bind(this)
        Hotstring.DefineProp("Call", {Call:this.__Hotstring.Bind(this)})
        ; These two throw critical recursion errors if defined with the normal syntax and AHK is ran in debugging mode
        HotstringRecognizer.DefineProp("MinSendLevel", {
            set:((hook, this, value, *) => hook.MinSendLevel := value).Bind(this.__Hook), 
            get:((hook, *) => hook.MinSendLevel).Bind(this.__Hook)})
        HotstringRecognizer.DefineProp("ResetKeys", 
            {set:((this, dummy, value, *) => (this.__ResetKeys := value, this.__Hook.KeyOpt(this.__ResetKeys, "N"), Value)).Bind(this), 
            get:((this, *) => this.__ResetKeys).Bind(this)})
    }

    static Start() {
        this.Reset()
        Hotstring("MouseReset", Hotstring("MouseReset")) ; activate or deactivate the relevant mouse hooks
        this.__Hook.Start()
        this.IsActive := 1
    }
    static Stop() => (this.__Hook.Stop(), this.IsActive := 0, this.__SetMouseReset(0))
    static Reset(ih:=0, vk:=0, *) => (vk = 8 ? this.__SetContent(SubStr(this.Content, 1, -1)) : this.__SetContent(""), this.Length := 0, this.__hWnd := DllCall("GetForegroundWindow", "ptr"))

    static __AddChar(ih, char) {
        hWnd := DllCall("GetForegroundWindow", "ptr")
        if this.__hWnd != hWnd
            this.__hWnd := hwnd, this.__SetContent("")  
        this.__SetContent(this.Content char), this.Length += 1
        if this.Length > 100
            this.Length := 50, this.Content := SubStr(this.Content, 52)
    }
    static __MouseReset(*) {
        if Hotstring("MouseReset")
            this.Reset()
    }
    static __Hotstring(BuiltInFunc, arg1, arg2?, arg3*) {
        switch arg1, 0 {
            case "MouseReset":
                if IsSet(arg2)
                    this.__SetMouseReset(arg2)
            case "Reset":
                this.Reset()
        }
        return (Func.Prototype.Call)(BuiltInFunc, arg1, arg2?, arg3*)
    }
    static __SetMouseReset(newValue) {
        static MouseRIProc := this.__MouseRawInputProc.Bind(this), DevSize := 8 + A_PtrSize, RIDEV_INPUTSINK := 0x00000100
            , RIDEV_REMOVE := 0x00000001, RAWINPUTDEVICE := Buffer(DevSize, 0), Active := 0
        if !!newValue = Active
            return
        if Active := !!newValue {
            NumPut("UShort", 1, "UShort", 2, "Uint", RIDEV_INPUTSINK, "Ptr", A_ScriptHwnd, RAWINPUTDEVICE)
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
        If !DllCall("GetRawInputData", "Ptr", lParam, "uint", 0x10000005, "Ptr", header, "Uint*", &pcbSize, "Uint", pcbSize)
            return 0
        ThisMouse := NumGet(header, 8, "UPtr")
        ; Find size of rawinput data - only needs to be run the first time.
        if (!iSize) {
            r := DllCall("GetRawInputData", "Ptr", lParam, "UInt", 0x10000003, "Ptr", 0, "UInt*", &iSize, "UInt", 8 + (A_PtrSize * 2))
            uRawInput := Buffer(iSize, 0)
        }
        ; Get RawInput data
        r := DllCall("GetRawInputData", "Ptr", lParam, "UInt", 0x10000003, "Ptr", uRawInput, "UInt*", &sz := iSize, "UInt", 8 + (A_PtrSize * 2))

        usButtonFlags := NumGet(uRawInput, offsets.usButtonFlags, "ushort")
        
        if usButtonFlags & 0x0001 || usButtonFlags & 0x0004 || usButtonFlags & 0x0010 || usButtonFlags & 0x0040 || usButtonFlags & 0x0100
            this.__MouseReset()
    }
    static __SetContent(Value) {
        if this.OnChange && HasMethod(this.OnChange) && this.Content !== Value
            SetTimer(this.OnChange.Bind(this.Content, Value), -1)
        this.Content := Value
    }
}

/**
 * InputBuffer can be used to buffer user input for keyboard, mouse, or both at once. 
 * The default InputBuffer (via the main class name) is keyboard only, but new instances
 * can be created via InputBuffer().
 * 
 * InputBuffer(keybd := true, mouse := false, timeout := 0)
 *      Creates a new InputBuffer instance. If keybd/mouse arguments are numeric then the default 
 *      InputHook settings are used, and if they are a string then they are used as the Option 
 *      arguments for InputHook and HotKey functions. Timeout can optionally be provided to call
 *      InputBuffer.Stop() automatically after the specified amount of milliseconds (as a failsafe).
 * 
 * InputBuffer.Start()               => initiates capturing input
 * InputBuffer.Release()             => releases buffered input and continues capturing input
 * InputBuffer.Stop(release := true) => releases buffered input and then stops capturing input
 * InputBuffer.ActiveCount           => current number of Start() calls
 *                                      Capturing will stop only when this falls to 0 (Stop() decrements it by 1)
 * InputBuffer.SendLevel             => SendLevel of the InputHook
 *                                      InputBuffers default capturing SendLevel is A_SendLevel+2, 
 *                                      and key release SendLevel is A_SendLevel+1.
 * InputBuffer.IsReleasing           => whether Release() is currently in action
 * InputBuffer.Buffer                => current buffered input in an array
 * 
 * Notes:
 * * Mouse input can't be buffered while AHK is doing something uninterruptible (eg busy with Send)
 */
class InputBuffer {
    Buffer := [], SendLevel := A_SendLevel + 2, ActiveCount := 0, IsReleasing := 0, ModifierKeyStates := Map()
        , MouseButtons := ["LButton", "RButton", "MButton", "XButton1", "XButton2", "WheelUp", "WheelDown"]
        , ModifierKeys := ["LShift", "RShift", "LCtrl", "RCtrl", "LAlt", "RAlt", "LWin", "RWin"]
    static __New() => this.DefineProp("Default", {value:InputBuffer()})
    static __Get(Name, Params) => this.Default.%Name%
    static __Set(Name, Params, Value) => this.Default.%Name% := Value
    static __Call(Name, Params) => this.Default.%Name%(Params*)
    __New(keybd := true, mouse := false, timeout := 0) {
        if !keybd && !mouse
            throw Error("At least one input type must be specified")
        this.Timeout := timeout
        this.Keybd := keybd, this.Mouse := mouse
        if keybd {
            if keybd is String {
                if RegExMatch(keybd, "i)I *(\d+)", &lvl)
                    this.SendLevel := Integer(lvl[1])
            }
            this.InputHook := InputHook(keybd is String ? keybd : "I" (this.SendLevel) " L0 B0")
            this.InputHook.NotifyNonText  := true
            this.InputHook.VisibleNonText := false
            this.InputHook.OnKeyDown      := this.BufferKey.Bind(this,,,, "Down")
            this.InputHook.OnKeyUp        := this.BufferKey.Bind(this,,,, "Up")
            this.InputHook.KeyOpt("{All}", "N S")
        }
        this.HotIfIsActive := this.GetActiveCount.Bind(this)
    }
    BufferMouse(ThisHotkey, Opts := "") {
        savedCoordMode := A_CoordModeMouse, CoordMode("Mouse", "Screen")
        MouseGetPos(&X, &Y)
        ThisHotkey := StrReplace(ThisHotkey, "Button")
        this.Buffer.Push(Format("{Click {1} {2} {3} {4}}", X, Y, ThisHotkey, Opts))
        CoordMode("Mouse", savedCoordMode)
    }
    BufferKey(ih, VK, SC, UD) => (this.Buffer.Push(Format("{{1} {2}}", GetKeyName(Format("vk{:x}sc{:x}", VK, SC)), UD)))
    Start() {
        this.ActiveCount += 1
        SetTimer(this.Stop.Bind(this), -this.Timeout)

        if this.ActiveCount > 1
            return

        this.Buffer := [], this.ModifierKeyStates := Map()
        for modifier in this.ModifierKeys
            this.ModifierKeyStates[modifier] := GetKeyState(modifier)

        if this.Keybd
            this.InputHook.Start()
        if this.Mouse {
            HotIf this.HotIfIsActive 
            if this.Mouse is String && RegExMatch(this.Mouse, "i)I *(\d+)", &lvl)
                this.SendLevel := Integer(lvl[1])
            opts := this.Mouse is String ? this.Mouse : ("I" this.SendLevel)
            for key in this.MouseButtons {
                if InStr(key, "Wheel")
                    HotKey key, this.BufferMouse.Bind(this), opts
                else {
                    HotKey key, this.BufferMouse.Bind(this,, "Down"), opts
                    HotKey key " Up", this.BufferMouse.Bind(this), opts
                }
            }
            HotIf ; Disable context sensitivity
        }
    }
    Release() {
        if this.IsReleasing || !this.Buffer.Length
            return []

        sent := [], clickSent := false, this.IsReleasing := 1
        if this.Mouse
            savedCoordMode := A_CoordModeMouse, CoordMode("Mouse", "Screen"), MouseGetPos(&X, &Y)

        ; Theoretically the user can still input keystrokes between ih.Stop() and Send, in which case
        ; they would get interspersed with Send. So try to send all keystrokes, then check if any more 
        ; were added to the buffer and send those as well until the buffer is emptied. 
        PrevSendLevel := A_SendLevel
        SendLevel this.SendLevel - 1

        ; Restore the state of any modifier keys before input buffering was started
        modifierList := ""
        for modifier, state in this.ModifierKeyStates
            if GetKeyState(modifier) != state
                modifierList .= "{" modifier (state ? " Down" : " Up") "}"
        if modifierList
            Send modifierList

        while this.Buffer.Length {
            key := this.Buffer.RemoveAt(1)
            sent.Push(key)
            if InStr(key, "{Click ")
                clickSent := true
            Send("{Blind}" key)
        }
        SendLevel PrevSendLevel

        if this.Mouse && clickSent {
            MouseMove(X, Y)
            CoordMode("Mouse", savedCoordMode)
        }
        this.IsReleasing := 0
        return sent
    }
    Stop(release := true) {
        if !this.ActiveCount
            return

        sent := release ? this.Release() : []

        if --this.ActiveCount
            return

        if this.Keybd
            this.InputHook.Stop()

        if this.Mouse {
            HotIf this.HotIfIsActive 
            for key in this.MouseButtons
                HotKey key, "Off"
            HotIf ; Disable context sensitivity
        }

        return sent
    }
    GetActiveCount(HotkeyName) => this.ActiveCount
}