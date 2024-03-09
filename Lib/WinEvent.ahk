#Requires AutoHotkey v2

/**
 * The WinEvent class can monitor window events for all windows or specific windows.  
 * Currently the following events are supported: `Show`, `Create`, `Close`, `Active`, `NotActive`, `Move`, 
 * `MoveStart`, `MoveEnd`, `Minimize`, `Restore`, `Maximize`. See comments for the functions for more information.
 * 
 * All the event initiation methods have the same syntax: 
 * `WinEvent.EventType(Callback, WinTitle:="", Count:=-1, WinText:="", ExcludeTitle:="", ExcludeText:="")`
 * where Callback is the function that will be called once the event happened, and Count specifies
 * the maximum amount of callbacks. 
 * The function returns an event hook object that describes the hook (see descriptions down below).
 * 
 * `Callback(eventObj, hWnd, dwmsEventTime)`
 *      `eventObj`     : the event hook object describing the hook
 *      `hWnd`         : the window handle that triggered the event
 *      `dwmsEventTime`: the `A_TickCount` for when the event happened
 * 
 * Hook object properties:
 * `EventHook.EventType`
 *      The name of the event type (Show, Close, etc)
 * `EventHook.MatchCriteria`
 *      The window matching criteria in array format `[WinTitle, WinText, ExcludeTitle, ExcludeText]`
 * `EventHook.Callback`
 *      The callback function
 * `EventHook.Count`
 *      The current count of how many times the callback may be called
 * 
 * Hook object methods:
 * `EventHook.Stop()`
 *      Stops the event hook
 * 
 * WinEvent methods (in addition to the event methods):
 * `WinEvent.Stop(EventType?, WinTitle:="", WinText:="", ExcludeTitle:="", ExcludeText:="")`
 *      Stops one or all event hooks.
 * `WinEvent.IsActive(EventType, WinTitle:="", WinText:="", ExcludeTitle:="", ExcludeText:="")
 *      Checks whether an event is active.
 * `WinEvent.IsEventTypeActive(EventType)`
 *      Checks whether any events for a given event type are active.
 */
class WinEvent {
    ; A curated list of event enumerations
    static EVENT_OBJECT_CREATE         := 0x8000,
           EVENT_OBJECT_DESTROY        := 0x8001,
           EVENT_OBJECT_SHOW           := 0x8002,
           EVENT_OBJECT_FOCUS          := 0x8005,
           EVENT_OBJECT_LOCATIONCHANGE := 0x800B,
           EVENT_SYSTEM_MINIMIZESTART  := 0x0016,
           EVENT_SYSTEM_MINIMIZEEND    := 0x0017,
           EVENT_SYSTEM_MOVESIZESTART  := 0x000A,
           EVENT_SYSTEM_MOVESIZEEND    := 0x000B,
           EVENT_SYSTEM_FOREGROUND     := 0x0003,
           EVENT_OBJECT_NAMECHANGE     := 0x800C

    /**
     * When a window is shown
     * @param {(eventObj, hWnd, dwmsEventTime) => Integer} Callback
     * - `hWnd`         : the window handle that triggered the event
     * - `dwmsEventTime`: the `A_TickCount` for when the event happened
     * @param {Number} Count Limits the number of times the callback will be called (eg for a one-time event set `Count` to 1).
     * @returns {WinEvent} 
     */
    static Show(Callback, WinTitle:="", Count:=-1, WinText:="", ExcludeTitle:="", ExcludeText:="") =>
        this("Show", Callback, Count, [WinTitle, WinText, ExcludeTitle, ExcludeText])

    /**
     * When a window is created, but not necessarily shown
     * @param {(eventObj, hWnd, dwmsEventTime) => Integer} Callback
     * - `hWnd`         : the window handle that triggered the event
     * - `dwmsEventTime`: the `A_TickCount` for when the event happened
     * @param {Number} Count Limits the number of times the callback will be called (eg for a one-time event set `Count` to 1).
     * @returns {WinEvent} 
     */
    static Create(Callback, WinTitle:="", Count:=-1, WinText:="", ExcludeTitle:="", ExcludeText:="") => 
        this("Create", Callback, Count, [WinTitle, WinText, ExcludeTitle, ExcludeText])
    
    /**
     * When a window is destroyed/closed
     * @param {(eventObj, hWnd, dwmsEventTime) => Integer} Callback
     * - `hWnd`         : the window handle that triggered the event
     * - `dwmsEventTime`: the `A_TickCount` for when the event happened
     * @param {Number} Count Limits the number of times the callback will be called (eg for a one-time event set `Count` to 1).
     * @returns {WinEvent} 
     */
    static Close(Callback, WinTitle:="", Count:=-1, WinText:="", ExcludeTitle:="", ExcludeText:="") => 
        this("Close", Callback, Count, [WinTitle, WinText, ExcludeTitle, ExcludeText])

    /**
     * When a window is activated/focused
     * @param {(eventObj, hWnd, dwmsEventTime) => Integer} Callback
     * - `hWnd`         : the window handle that triggered the event
     * - `dwmsEventTime`: the `A_TickCount` for when the event happened
     * @param {Number} Count Limits the number of times the callback will be called (eg for a one-time event set `Count` to 1).
     * @returns {WinEvent} 
     */
    static Active(Callback, WinTitle:="", Count:=-1, WinText:="", ExcludeTitle:="", ExcludeText:="") => 
        this("Active", Callback, Count, [WinTitle, WinText, ExcludeTitle, ExcludeText])

    /**
     * When a window is inactivated/unfocused
     * @param {(eventObj, hWnd, dwmsEventTime) => Integer} Callback
     * - `hWnd`         : the window handle that triggered the event
     * - `dwmsEventTime`: the `A_TickCount` for when the event happened
     * @param {Number} Count Limits the number of times the callback will be called (eg for a one-time event set `Count` to 1).
     * @returns {WinEvent} 
     */
    static NotActive(Callback, WinTitle:="", Count:=-1, WinText:="", ExcludeTitle:="", ExcludeText:="") => 
        this("NotActive", Callback, Count, [WinTitle, WinText, ExcludeTitle, ExcludeText])

    /**
     * When a window is moved or resized
     * @param {(eventObj, hWnd, dwmsEventTime) => Integer} Callback
     * - `hWnd`         : the window handle that triggered the event
     * - `dwmsEventTime`: the `A_TickCount` for when the event happened
     * @param {Number} Count Limits the number of times the callback will be called (eg for a one-time event set `Count` to 1).
     * @returns {WinEvent} 
     */
    static Move(Callback, WinTitle:="", Count:=-1, WinText:="", ExcludeTitle:="", ExcludeText:="") => 
        this("Move", Callback, Count, [WinTitle, WinText, ExcludeTitle, ExcludeText])

    /**
     * When a window is starting to be moved or resized
     * @param {(eventObj, hWnd, dwmsEventTime) => Integer} Callback
     * - `hWnd`         : the window handle that triggered the event
     * - `dwmsEventTime`: the `A_TickCount` for when the event happened
     * @param {Number} Count Limits the number of times the callback will be called (eg for a one-time event set `Count` to 1).
     * @returns {WinEvent} 
     */
    static MoveStart(Callback, WinTitle:="", Count:=-1, WinText:="", ExcludeTitle:="", ExcludeText:="") => 
        this("MoveStart", Callback, Count, [WinTitle, WinText, ExcludeTitle, ExcludeText])

    /**
     * When a window has been moved or resized
     * @param {(eventObj, hWnd, dwmsEventTime) => Integer} Callback
     * - `hWnd`         : the window handle that triggered the event
     * - `dwmsEventTime`: the `A_TickCount` for when the event happened
     * @param {Number} Count Limits the number of times the callback will be called (eg for a one-time event set `Count` to 1).
     * @returns {WinEvent} 
     */
    static MoveEnd(Callback, WinTitle:="", Count:=-1, WinText:="", ExcludeTitle:="", ExcludeText:="") => 
        this("MoveEnd", Callback, Count, [WinTitle, WinText, ExcludeTitle, ExcludeText])

    /**
     * When a window is minimized
     * @param {(eventObj, hWnd, dwmsEventTime) => Integer} Callback
     * - `hWnd`         : the window handle that triggered the event
     * - `dwmsEventTime`: the `A_TickCount` for when the event happened
     * @param {Number} Count Limits the number of times the callback will be called (eg for a one-time event set `Count` to 1).
     * @returns {WinEvent} 
     */
    static Minimize(Callback, WinTitle:="", Count:=-1, WinText:="", ExcludeTitle:="", ExcludeText:="") => 
        this("Minimize", Callback, Count, [WinTitle, WinText, ExcludeTitle, ExcludeText])

    /**
     * When a window is restored
     * @param {(eventObj, hWnd, dwmsEventTime) => Integer} Callback
     * - `hWnd`         : the window handle that triggered the event
     * - `dwmsEventTime`: the `A_TickCount` for when the event happened
     * @param {Number} Count Limits the number of times the callback will be called (eg for a one-time event set `Count` to 1).
     * @returns {WinEvent} 
     */
    static Restore(Callback, WinTitle:="", Count:=-1, WinText:="", ExcludeTitle:="", ExcludeText:="") => 
        this("Restore", Callback, Count, [WinTitle, WinText, ExcludeTitle, ExcludeText])

    /**
     * When a window is maximized
     * @param {(eventObj, hWnd, dwmsEventTime) => Integer} Callback
     * - `hWnd`         : the window handle that triggered the event
     * - `dwmsEventTime`: the `A_TickCount` for when the event happened
     * @param {Number} Count Limits the number of times the callback will be called (eg for a one-time event set `Count` to 1).
     * @returns {WinEvent} 
     */
    static Maximize(Callback, WinTitle:="", Count:=-1, WinText:="", ExcludeTitle:="", ExcludeText:="") => 
        this("Maximize", Callback, Count, [WinTitle, WinText, ExcludeTitle, ExcludeText])

    /**
     * Stops one or all event hooks
     * @param EventType The name of the event function (eg Close).
     * If this isn't specified then all event hooks will be stopped.
     */
    static Stop(EventType?, WinTitle:="", WinText:="", ExcludeTitle:="", ExcludeText:="") {
        local MatchMap, Hook
        if !IsSet(EventType) {
            for EventType, MatchMap in this.__RegisteredEvents
                for MatchCriteria, Hook in MatchMap
                    Hook.Stop()
            this.__New()
            return
        }
        if !this.__RegisteredEvents.Has(EventType)
            return
        for MatchCriteria, EventObj in this.__RegisteredEvents[EventType].Clone()
            if MatchCriteria[1] = WinTitle && MatchCriteria[2] = WinText && MatchCriteria[3] = ExcludeTitle && MatchCriteria[4] = ExcludeText
                EventObj.Stop()
    }

    /**
     * Checks whether an event is active
     * @param EventType The name of the event function (eg Close)
     */
    static IsActive(EventType, WinTitle:="", WinText:="", ExcludeTitle:="", ExcludeText:="") {
        if !this.__RegisteredEvents.Has(EventType)
            return 0
        for MatchCriteria, EventObj in this.__RegisteredEvents[EventType]
            if MatchCriteria[1] = WinTitle && MatchCriteria[2] = WinText && MatchCriteria[3] = ExcludeTitle && MatchCriteria[4] = ExcludeText
                return 1
        return 0
    }

    /**
     * Checks whether any events for a given event type are active
     * @param EventType The name of the event function (eg Close)
     */
    static IsEventTypeActive(EventType) => this.__RegisteredEvents.Has(EventType)

    ; Stops the event hook, same as if the object was destroyed.
    Stop() => (this.__Delete(), this.MatchCriteria := "", this.Callback := "")

    class Hook {
        /**
         * Sets a new event hook using SetWinEventHook and returns on object describing the hook. 
         * When the object is released, the hook is also released.
         * @param {(hWinEventHook, event, hwnd, idObject, idChild, idEventThread, dwmsEventTime) => Integer} callbackFunc The function that will be called, which needs to accept 7 arguments.
         * @param {Integer} [eventMin] Optional: Specifies the event constant for the lowest event value in the range of events that are handled by the hook function.  
         *  Default is the lowest possible event value.  
         * - See more about [event constants](https://learn.microsoft.com/en-us/windows/win32/winauto/event-constants)
         * - [Msaa Events List](Https://Msdn.Microsoft.Com/En-Us/Library/Windows/Desktop/Dd318066(V=Vs.85).Aspx)
         * - [System-Level And Object-Level Events](Https://Msdn.Microsoft.Com/En-Us/Library/Windows/Desktop/Dd373657(V=Vs.85).Aspx)
         * - [Console Accessibility](Https://Msdn.Microsoft.Com/En-Us/Library/Ms971319.Aspx)
         * @param {Integer} [eventMax] Optional: Specifies the event constant for the highest event value in the range of events that are handled by the hook function.
         *  If eventMin is omitted then the default is the highest possible event value.
         *  If eventMin is specified then the default is eventMin.
         * @param {Integer|String} [winTitle=0] Optional: WinTitle of a certain window to hook to. Default is system-wide hook.
         * @param {Integer} [PID=0] Optional: process ID of the process for which threads to hook to. Default is system-wide hook.
         * @param {Integer} [flags=0] Flag values that specify the location of the hook function and of the events to be skipped.
         *  Default is `WINEVENT_OUTOFCONTEXT` = 0. 
         * @returns {WinEventHook} 
         */
        __New(callbackFunc, eventMin?, eventMax?, winTitle := 0, PID := 0, flags := 0) {
            if !IsSet(eventMin)
                eventMin := 0x00000001, eventMax := IsSet(eventMax) ? eventMax : 0x7fffffff
            else if !IsSet(eventMax)
                eventMax := eventMin
            this.winTitle := winTitle, this.flags := flags, this.eventMin := eventMin, this.eventMax := eventMax, this.threadId := 0
            if !HasMethod(callbackFunc)
                throw ValueError("The callbackFunc argument must be a function", -1)
            if winTitle != 0 {
                if !(this.winTitle := WinExist(winTitle))
                    throw TargetError("Window not found", -1)
                this.threadId := DllCall("GetWindowThreadProcessId", "Int", this.winTitle, "UInt*", &PID)
            }
            this.pCallback := CallbackCreate(callbackFunc, "C Fast", 7)
            , this.hHook := DllCall("SetWinEventHook", "UInt", eventMin, "UInt", eventMax, "Ptr", 0, "Ptr", this.pCallback, "UInt", this.PID := PID, "UInt", this.threadId, "UInt", flags)
        }
        __Delete() {
            DllCall("UnhookWinEvent", "Ptr", this.hHook)
            , CallbackFree(this.pCallback)
        }
    }

    ; ONLY INTERNAL METHODS AHEAD

    static __RequiredHooks := Map("Show", [this.EVENT_OBJECT_SHOW], "Create", [this.EVENT_OBJECT_CREATE]
        , "Close", [this.EVENT_OBJECT_CREATE, this.EVENT_OBJECT_NAMECHANGE, this.EVENT_OBJECT_DESTROY]
        , "Active", [this.EVENT_SYSTEM_FOREGROUND], "NotActive", [this.EVENT_SYSTEM_FOREGROUND]
        , "Move", [this.EVENT_OBJECT_LOCATIONCHANGE], "MoveStart", [this.EVENT_SYSTEM_MOVESIZESTART]
        , "MoveEnd", [this.EVENT_SYSTEM_MOVESIZEEND], "Minimize", [this.EVENT_SYSTEM_MINIMIZESTART]
        , "Maximize", [this.EVENT_OBJECT_LOCATIONCHANGE])

    ; Internal variables: keep track of registered events (the match criteria) and registered window hooks
    static __RegisteredEvents := Map(), __Hooks := Map()

    static __New() {
        this.Prototype.__WinEvent := this
        this.__RegisteredEvents := Map(), this.__RegisteredEvents.CaseSense := 0
        this.__Hooks := Map(), this.__Hooks.CaseSense := 0
    }
    ; Activates all necessary window hooks for a given WinEvent type
    static __AddRequiredHooks(EventType) {
        local _, Hook
        for _, Hook in this.__RequiredHooks[EventType]
            this.__AddHook(Hook)
    }
    ; Removes (and/or decreases ref count) all necessary window hooks for a given WinEvent type
    static __RemoveRequiredHooks(EventType) {
        local _, Hook
        for _, Hook in this.__RequiredHooks[EventType]
            this.__RemoveHook(Hook)
    }
    ; Internal use: activates a new hook if not already active and increases its reference count
    static __AddHook(Hook) {
        if !this.__Hooks.Has(Hook)
            this.__Hooks[Hook] := this.Hook(this.__HandleWinEvent.Bind(this), Hook), this.__Hooks[Hook].RefCount := 0
        this.__Hooks[Hook].RefCount++
    }
    ; Internal use: decreases a hooks reference count and removes it if it falls to 0
    static __RemoveHook(Hook) {
        this.__Hooks[Hook].RefCount--
        if !this.__Hooks[Hook].RefCount
            this.__Hooks.Delete(Hook)
    }
    ; Internal use: creates a new WinEvent object, which contains info about the registered event
    ; such as the type, callback function, match criteria etc.
    __New(EventType, Callback, Count, MatchCriteria) {
        __WinEvent := this.__WinEvent, this.EventType := EventType, this.MatchCriteria := MatchCriteria, this.Callback := Callback, this.Count := Count
        if EventType = "Close" {
            this.__UpdateMatchingWinList()
            __WinEvent.__UpdateWinList()
        } else if EventType = "NotActive" {
            try this.IsActive := WinActive(MatchCriteria*)
            catch
                this.IsActive := 0
        }
        if !__WinEvent.__RegisteredEvents.Has(EventType)
            __WinEvent.__RegisteredEvents[EventType] := Map()
        __WinEvent.__RegisteredEvents[EventType][MatchCriteria] := this
        __WinEvent.__AddRequiredHooks(EventType)
    }
    ; Internal use: once a WinEvent object is destroyed, deregister the match criteria and remove 
    ; the hook (if no other WinEvent objects depend on it)
    __Delete() {
        if !this.MatchCriteria
            return
        this.__WinEvent.__RegisteredEvents[this.EventType].Delete(this.MatchCriteria)
        this.__WinEvent.__RemoveRequiredHooks(this.EventType)
    }
    ; Internal use: sets a timer for the callback function (to avoid the thread being Critical
    ; because the HandleWinEvent thread is Critical). Also keeps track of how many times the 
    ; callback has been called.
    __ActivateCallback(args*) {
        SetTimer this.Callback.Bind(args*), -1
        if --this.Count = 0
            this.Stop()
    }
    ; Internal use: handles the event called by SetWinEventHook. 
    static __HandleWinEvent(hWinEventHook, event, hwnd, idObject, idChild, idEventThread, dwmsEventTime) {
        Critical -1
        static OBJID_WINDOW := 0, INDEXID_CONTAINER := 0, EVENT_OBJECT_CREATE := 0x8000, EVENT_OBJECT_DESTROY := 0x8001, EVENT_OBJECT_SHOW := 0x8002, EVENT_OBJECT_FOCUS := 0x8005, EVENT_OBJECT_LOCATIONCHANGE := 0x800B, EVENT_SYSTEM_MINIMIZESTART := 0x0016, EVENT_SYSTEM_MINIMIZEEND := 0x0017, EVENT_SYSTEM_MOVESIZESTART := 0x000A, EVENT_SYSTEM_MOVESIZEEND := 0x000B, EVENT_SYSTEM_FOREGROUND := 0x0003, EVENT_OBJECT_NAMECHANGE := 0x800C ; These are duplicated here for performance reasons

        local PrevDHW := DetectHiddenWindows(1), HookObj, MatchCriteria
        idObject := idObject << 32 >> 32, idChild := idChild << 32 >> 32, event &= 0xFFFFFFFF, idEventThread &= 0xFFFFFFFF, dwmsEventTime &= 0xFFFFFFFF ; convert to INT/UINT

        if (event = EVENT_OBJECT_DESTROY) {
            if !this.WinList.Has(hWnd)
                goto Cleanup
            for MatchCriteria, HookObj in this.__RegisteredEvents["Close"] {
                if HookObj.MatchingWinList.Has(hWnd)
                    HookObj.__ActivateCallback(HookObj, hWnd, dwmsEventTime)
                HookObj.__UpdateMatchingWinList()
            }
            this.__UpdateWinList()
            goto Cleanup
        }
        if (idObject != OBJID_WINDOW || idChild != INDEXID_CONTAINER || !DllCall("IsTopLevelWindow", "ptr", hWnd))
            goto Cleanup
        if (event = EVENT_OBJECT_NAMECHANGE || event = EVENT_OBJECT_CREATE) && this.__RegisteredEvents.Has("Close") {
            for MatchCriteria, HookObj in this.__RegisteredEvents["Close"]
                HookObj.__UpdateMatchingWinList()
            if event = EVENT_OBJECT_CREATE
                this.__UpdateWinList()
        }
        if (event = EVENT_OBJECT_LOCATIONCHANGE && this.__RegisteredEvents.Has("Maximize")) { ; Only handles "Maximize"
            for MatchCriteria, HookObj in this.__RegisteredEvents["Maximize"] {
                if WinExist(MatchCriteria[1] " ahk_id " hWnd, MatchCriteria[2], MatchCriteria[3], MatchCriteria[4]) {
                    if WinGetMinMax(hWnd) != 1
                        continue
                    HookObj.__ActivateCallback(HookObj, hWnd, dwmsEventTime)
                }
            }
        } 
        if ((event = EVENT_OBJECT_LOCATIONCHANGE && EventName := "Move")
            || (event = EVENT_OBJECT_CREATE && EventName := "Create") 
            || (event = EVENT_OBJECT_SHOW && EventName := "Show")
            || (event = EVENT_SYSTEM_MOVESIZESTART && EventName := "MoveStart")
            || (event = EVENT_SYSTEM_MOVESIZEEND && EventName := "MoveEnd")
            || (event = EVENT_SYSTEM_MINIMIZESTART && EventName := "Minimize")
            || (event = EVENT_SYSTEM_MINIMIZEEND && EventName := "Restore")
            || (event = EVENT_SYSTEM_FOREGROUND && EventName := "Active")) && this.__RegisteredEvents.Has(EventName) {
            for MatchCriteria, HookObj in this.__RegisteredEvents[EventName] {
                if exist := WinExist(MatchCriteria[1] " ahk_id " hWnd, MatchCriteria[2], MatchCriteria[3], MatchCriteria[4])
                    HookObj.__ActivateCallback(HookObj, hWnd, dwmsEventTime)
            }
        } 
        if (event = EVENT_SYSTEM_FOREGROUND && this.__RegisteredEvents.Has("NotActive")) {
            for MatchCriteria, HookObj in this.__RegisteredEvents["NotActive"] {
                try if HookObj.IsActive && !WinActive(MatchCriteria*) {
                    HookObj.__ActivateCallback(HookObj, HookObj.IsActive, dwmsEventTime)
                    HookObj.IsActive := 0
                }
                if WinActive(MatchCriteria[1] " ahk_id " hWnd, MatchCriteria[2], MatchCriteria[3], MatchCriteria[4])
                    HookObj.IsActive := hWnd
            }
        }
        Cleanup:
        DetectHiddenWindows PrevDHW
        Critical("Off"), Sleep(-1) ; Check the message queue immediately
    }
    ; Internal use: keeps track of all open windows to only handle top-level windows
    static __UpdateWinList() {
        local WinList := WinGetList(),  WinListMap := Map(), hWnd
        for hWnd in WinList
            WinListMap[hWnd] := 1
        this.WinList := WinListMap
    }
    ; Internal use: keeps track of open windows that match the criteria, because matching for name
    ; class etc wouldn't work after the window is already destroyed. 
    __UpdateMatchingWinList() {
        if !this.MatchCriteria
            return
        local MatchingWinList := WinGetList(this.MatchCriteria*), MatchingWinListMap := Map(), hWnd
        for hWnd in MatchingWinList
            MatchingWinListMap[hWnd] := 1
        this.MatchingWinList := MatchingWinListMap
    }
}
