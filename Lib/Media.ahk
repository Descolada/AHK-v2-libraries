/**
 * Implements UWP Media Control, allowing access and control of the playing media (but not any media,
 * only UWP ones that are notified by a tray tip with the play-pause buttons and playing song title).
 * 
 * Media class main methods:
 * Media.GetCurrentSession()
 *      Gets the current session. This is the session the system believes the user would most likely want to control.
 * Media.GetSessions()
 *      Gets all of the available sessions.
 * Media.AddCurrentSessionChangedEvent(funcObj)
 *      Registers a new event handler that is called when the current session changes.
 * Media.AddSessionsChangedEvent(funcObj)
 *      Registers a new event handler that is called when a session is added/removed
 * 
 * Session class methods:
 * Session.Play()
 * Session.Pause()
 * Session.TogglePlayPause()
 * Session.Stop()
 * Session.Record()
 * Session.FastForward()
 * Session.Rewind()
 * Session.SkipNext()
 * Session.SkipPrevious()
 * Session.ChangeChannelUp()
 * Session.ChangeChannelDown()
 * Session.ChangeAutoRepeatMode(mode)
 * Session.ChangePlaybackRate(rate)
 * Session.ChangeShuffleActive(state)
 * Session.ChangePlaybackPosition(pos)
 * Session.AddTimelinePropertiesChangedEvent(funcObj)
 * Session.AddPlaybackInfoChangedEvent(funcObj)
 * Session.AddMediaPropertiesChangedEvent(funcObj)
 * Session.UpdateTimelineProperties()
 * Session.UpdatePlaybackInfo()
 * 
 * Session properties
 * Session.SourceAppUserModelId
 *      Gets the App user model Id of the source app of the session. 
 *      This is usually the app executable name, for example Spotify.exe or Chrome.exe.
 * Session.Title
 * Session.Subtitle
 * Session.AlbumArtist
 * Session.Artist
 * Session.AlbumTitle
 * Session.TrackNumber
 * Session.Genres
 *      Returns an array of genres
 * Session.AlbumTrackCount
 * Session.Thumbnail
 *      Returns a IRandomAccessStreamWithContentType object of the thumbnail.
 *      This can be converted to other formats with for example the ImagePut library.
 * 
 * Timeline properties:
 * Session.StartTime
 * Session.EndTime
 * Session.MinSeekTime
 * Session.MaxSeekTime
 * Session.Position
 * Session.LastUpdatedTime
 * 
 * Playback info properties:
 * Session.PlaybackStatus
 * Session.PlaybackType
 * Session.AutoRepeatMode
 * Session.PlaybackRate
 * Session.IsShuffleActive
 * Session.IsPlayEnabled
 * Session.IsPauseEnabled
 * Session.IsStopEnabled
 * Session.IsRecordEnabled
 * Session.IsFastForwardEnabled
 * Session.IsRewindEnabled
 * Session.IsNextEnabled
 * Session.IsPreviousEnabled
 * Session.IsChannelUpEnabled
 * Session.IsChannelDownEnabled
 * Session.IsPlayPauseToggleEnabled
 * Session.IsShuffleEnabled
 * Session.IsRepeatEnabled
 * Session.IsPlaybackRateEnabled
 * Session.IsPlaybackPositionEnabled
 * 
 * Event handler functions need to accept two arguments. If the registered event was
 * TimelinePropertiesChanged, PlaybackInfoChanged or AddMediaPropertiesChanged, then the
 * first argument will be the session that was changed. Otherwise the other arguments are currently
 * unusable.
 * Event registering methods (eg Session.AddPlaybackInfoChangedEvent) return an event handler object, 
 * and calling EventHandler.Remove() stops listening for the event.
 * 
 */

class Media {
    static IID_IAsyncInfo := "{00000036-0000-0000-C000-000000000046}"
         , IID_ITypedEventHandler_PlaybackInfoChangedEvent := "{2bdf1426-d41f-5896-897f-efc0b0fa7392}"
         , IID_ITypedEventHandler_MediaPropertiesChangedEvent := "{0f2ce2b7-afa7-5ed0-8cb6-8c40cf9b3a5f}"
         , IID_ITypedEventHandler_TimelinePropertiesChangedEvent := "{e8bf62af-fac1-5fff-9053-0bf191ae777e}"
         , IID_ITypedEventHandler_CurrentSessionChangedEvent := "{228bd0ed-1fa2-5e9b-a6ec-42566173103b}"
         , IID_ITypedEventHandler_SessionsChangedEvent := "{2e2a8630-dc8c-530a-9746-bc984d4b029e}"
         , RegisteredEvents := Map()
         , PlaybackStatus := {Closed:0, Opened:1, Changing:2, Stopped:3, Playing:4, Paused:5, base:this.Enumeration.Prototype}
         , PlaybackType := {Unknown:0, Audio:1, Video:2, Image:3, base:this.Enumeration.Prototype}

    static __New() {
        this.prototype.__Media := this, this.IBase.prototype.__Media := this, this.EventHandler.prototype.__Media := this
        this.Session.base := this.IBase, this.Session.prototype.base := this.IBase.prototype ; Session extends Media.IBase
        
        this.GlobalSystemMediaTransportControlsSessionManagerStatics := this.CreateClass("Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager", "{2050c4ee-11a0-57de-aed7-c97c70338245}")
        ComCall(6, this.GlobalSystemMediaTransportControlsSessionManagerStatics, "ptr*", GlobalSystemMediaTransportControlsSessionManager:=Media.IBase())   ; GlobalSystemMediaTransportControlsSessionManager.RequestAsync
        this.WaitForAsync(&GlobalSystemMediaTransportControlsSessionManager)
        this.GlobalSystemMediaTransportControlsSessionManager := GlobalSystemMediaTransportControlsSessionManager
    }

    class Session {
        SourceAppUserModelId {
            get {
                ComCall(6, this, "ptr*", hValue:=this.__Media.HString())
                buf := DllCall("Combase.dll\WindowsGetStringRawBuffer", "ptr", hValue, "uint*", &length:=0, "ptr")
                this.DefineProp("SourceAppUserModelId", {Value:StrGet(buf, "UTF-16")})
                return this.SourceAppUserModelId
            }
        }

        ;; internal
        IGlobalSystemMediaTransportControlsSessionMediaProperties {
            get {
                ComCall(7, this, "ptr*", IGlobalSystemMediaTransportControlsSessionMediaProperties:=this.__Media.IBase()) ; TryGetMediaPropertiesAsync
                this.__Media.WaitForAsync(&IGlobalSystemMediaTransportControlsSessionMediaProperties)
                this.DefineProp("IGlobalSystemMediaTransportControlsSessionMediaProperties", {value:IGlobalSystemMediaTransportControlsSessionMediaProperties})
                return this.IGlobalSystemMediaTransportControlsSessionMediaProperties
            }
        }

		Title {
			get => (ComCall(6, this.IGlobalSystemMediaTransportControlsSessionMediaProperties, "ptr*", hString:=this.__Media.HString()), hString[])
		}
		Subtitle {
			get => (ComCall(7, this.IGlobalSystemMediaTransportControlsSessionMediaProperties, "ptr*", hString:=this.__Media.HString()), hString[])
		}
		AlbumArtist {
			get => (ComCall(8, this.IGlobalSystemMediaTransportControlsSessionMediaProperties, "ptr*", hString:=this.__Media.HString()), hString[])
		}
		Artist {
			get => (ComCall(9, this.IGlobalSystemMediaTransportControlsSessionMediaProperties, "ptr*", hString:=this.__Media.HString()), hString[])
		}
		AlbumTitle {
			get => (ComCall(10, this.IGlobalSystemMediaTransportControlsSessionMediaProperties, "ptr*", hString:=this.__Media.HString()), hString[])
		}
		TrackNumber {
			get => (ComCall(11, this.IGlobalSystemMediaTransportControlsSessionMediaProperties, "int*", &value:=0), value)
		}
		Genres {
			get {
                ComCall(12, this.IGlobalSystemMediaTransportControlsSessionMediaProperties, "ptr*", IVector:=this.__Media.IBase())
                arr := this.__Media.VectorToArray(IVector, this.__Media.HString)
                Loop arr.Length
                    arr[A_Index] := arr[A_Index][]
                return arr
            }
		}
		AlbumTrackCount {
			get => (ComCall(13, this.IGlobalSystemMediaTransportControlsSessionMediaProperties, "int*", &value:=0), value)
		}
		Thumbnail {
			get {
                ComCall(15, this.IGlobalSystemMediaTransportControlsSessionMediaProperties, "ptr*", IRandomAccessStreamReference:=this.__Media.IBase())
                ComCall(6, IRandomAccessStreamReference, "ptr*", IRandomAccessStreamWithContentType:=this.__Media.IBase())
                this.__Media.WaitForAsync(&IRandomAccessStreamWithContentType)
                return IRandomAccessStreamWithContentType
            }
		}

        ;; internal
        IGlobalSystemMediaTransportControlsSessionTimelineProperties {
            get => this.UpdateTimelineProperties()
        }

        UpdateTimelineProperties() {
            ComCall(8, this, "ptr*", IGlobalSystemMediaTransportControlsSessionTimelineProperties:=this.__Media.IBase()) ; GetTimelineProperties()
            this.DefineProp("IGlobalSystemMediaTransportControlsSessionTimelineProperties", {value:IGlobalSystemMediaTransportControlsSessionTimelineProperties})
            return this.IGlobalSystemMediaTransportControlsSessionTimelineProperties
        }

        StartTime {
            get => (ComCall(6, this.IGlobalSystemMediaTransportControlsSessionTimelineProperties, "int64*", &value:=0), value//10000000)
        }
        EndTime {
            get => (ComCall(7, this.IGlobalSystemMediaTransportControlsSessionTimelineProperties, "int64*", &value:=0), value//10000000)
        }
        MinSeekTime {
            get => (ComCall(8, this.IGlobalSystemMediaTransportControlsSessionTimelineProperties, "int64*", &value:=0), value//10000000)
        }
        MaxSeekTime {
            get => (ComCall(9, this.IGlobalSystemMediaTransportControlsSessionTimelineProperties, "int64*", &value:=0), value//10000000)
        }
        Position {
            get => (ComCall(10, this.IGlobalSystemMediaTransportControlsSessionTimelineProperties, "int64*", &value:=0), value//10000000)
        }
        LastUpdatedTime {
            get => (ComCall(11, this.IGlobalSystemMediaTransportControlsSessionTimelineProperties, "int64*", &value:=0), value//10000000)
        }

        ;; internal
        IGlobalSystemMediaTransportControlsSessionPlaybackInfo {
            get => this.UpdatePlaybackInfo()
        }

        UpdatePlaybackInfo() {
            ComCall(9, this, "ptr*", IGlobalSystemMediaTransportControlsSessionPlaybackInfo:=this.__Media.IBase()) ; GetPlaybackInfo()
            this.DefineProp("IGlobalSystemMediaTransportControlsSessionPlaybackInfo", {value:IGlobalSystemMediaTransportControlsSessionPlaybackInfo})
            return this.IGlobalSystemMediaTransportControlsSessionPlaybackInfo
        }

        /**
         * The different states of playback the session could be in.
         * 
         * Possible return values:
         * 0 = The media is closed.
         * 1 = The media is opened.
         * 2 = The media is changing.
         * 3 = The media is stopped.
         * 4 = The media is playing.
         * 5 = The media is paused.
         */
        PlaybackStatus {
            get => (ComCall(7, this.IGlobalSystemMediaTransportControlsSessionPlaybackInfo, "int*", &value:=0), value) ; get_PlaybackStatus
        }
        /**
         * Defines values for the types of media playback
         * 
         * 0 = The media type is unknown.
         * 1 = The media type is audio music.
         * 2 = The media type is video.
         * 3 = The media type is an image.
         */
        PlaybackType {
            get {
                ComCall(8, this.IGlobalSystemMediaTransportControlsSessionPlaybackInfo, "ptr*", IReferenceMediaPlaybackType:=this.__Media.IBase())
                ComCall(6, IReferenceMediaPlaybackType, "int*", &value:=0)
                return value
            }
        }
        /**
         * Specifies the auto repeat mode for media playback.
         * 
         * 0 = No repeating.
         * 1 = Repeat the current track.
         * 2 = Repeat the current list of tracks.
         */
        AutoRepeatMode {
            get {
                ComCall(9, this.IGlobalSystemMediaTransportControlsSessionPlaybackInfo, "ptr*", IReferenceMediaPlaybackAutoRepeatType:=this.__Media.IBase())
                ComCall(6, IReferenceMediaPlaybackAutoRepeatType, "int*", &value:=0)
                return value
            }
        }
        ; A value indicating the playback rate, 1 being normal playback.
        PlaybackRate {
            get => (ComCall(10, this.IGlobalSystemMediaTransportControlsSessionPlaybackInfo, "double*", &value:=0), value)
        }
        ; True if the session is currently shuffling; otherwise, false.
        IsShuffleActive {
            get => (ComCall(11, this.IGlobalSystemMediaTransportControlsSessionPlaybackInfo, "int*", &value:=0), value)
        }

        ;; internal
        IGlobalSystemMediaTransportControlsSessionPlaybackControls {
            get {
                ComCall(6, this.IGlobalSystemMediaTransportControlsSessionPlaybackInfo, "ptr*", IGlobalSystemMediaTransportControlsSessionPlaybackControls:=this.__Media.IBase())
                this.DefineProp("IGlobalSystemMediaTransportControlsSessionPlaybackControls", {value:IGlobalSystemMediaTransportControlsSessionPlaybackControls})
                return this.IGlobalSystemMediaTransportControlsSessionPlaybackControls
            }
        }

		IsPlayEnabled {
			get => (ComCall(6, this.IGlobalSystemMediaTransportControlsSessionPlaybackControls, "int*", &value:=0), value)
		}
		IsPauseEnabled {
			get => (ComCall(7, this.IGlobalSystemMediaTransportControlsSessionPlaybackControls, "int*", &value:=0), value)
		}
		IsStopEnabled {
			get => (ComCall(8, this.IGlobalSystemMediaTransportControlsSessionPlaybackControls, "int*", &value:=0), value)
		}
		IsRecordEnabled {
			get => (ComCall(9, this.IGlobalSystemMediaTransportControlsSessionPlaybackControls, "int*", &value:=0), value)
		}
		IsFastForwardEnabled {
			get => (ComCall(10, this.IGlobalSystemMediaTransportControlsSessionPlaybackControls, "int*", &value:=0), value)
		}
		IsRewindEnabled {
			get => (ComCall(11, this.IGlobalSystemMediaTransportControlsSessionPlaybackControls, "int*", &value:=0), value)
		}
		IsNextEnabled {
			get => (ComCall(12, this.IGlobalSystemMediaTransportControlsSessionPlaybackControls, "int*", &value:=0), value)
		}
		IsPreviousEnabled {
			get => (ComCall(13, this.IGlobalSystemMediaTransportControlsSessionPlaybackControls, "int*", &value:=0), value)
		}
		IsChannelUpEnabled {
			get => (ComCall(14, this.IGlobalSystemMediaTransportControlsSessionPlaybackControls, "int*", &value:=0), value)
		}
		IsChannelDownEnabled {
			get => (ComCall(15, this.IGlobalSystemMediaTransportControlsSessionPlaybackControls, "int*", &value:=0), value)
		}
		IsPlayPauseToggleEnabled {
			get => (ComCall(16, this.IGlobalSystemMediaTransportControlsSessionPlaybackControls, "int*", &value:=0), value)
		}
		IsShuffleEnabled {
			get => (ComCall(17, this.IGlobalSystemMediaTransportControlsSessionPlaybackControls, "int*", &value:=0), value)
		}
		IsRepeatEnabled {
			get => (ComCall(18, this.IGlobalSystemMediaTransportControlsSessionPlaybackControls, "int*", &value:=0), value)
		}
		IsPlaybackRateEnabled {
			get => (ComCall(19, this.IGlobalSystemMediaTransportControlsSessionPlaybackControls, "int*", &value:=0), value)
		}
		IsPlaybackPositionEnabled {
			get => (ComCall(20, this.IGlobalSystemMediaTransportControlsSessionPlaybackControls, "int*", &value:=0), value)
		}

        Play() => (ComCall(10, this, "ptr*", IAsync:=this.__Media.IBase()), this.__Media.WaitForAsync(&IAsync, "int*"), IAsync) 
        Pause() => (ComCall(11, this, "ptr*", IAsync:=this.__Media.IBase()), this.__Media.WaitForAsync(&IAsync, "int*"), IAsync) 
        Stop() => (ComCall(12, this, "ptr*", IAsync:=this.__Media.IBase()), this.__Media.WaitForAsync(&IAsync, "int*"), IAsync)
        Record() => (ComCall(13, this, "ptr*", IAsync:=this.__Media.IBase()), this.__Media.WaitForAsync(&IAsync, "int*"), IAsync) 
        FastForward() => (ComCall(14, this, "ptr*", IAsync:=this.__Media.IBase()), this.__Media.WaitForAsync(&IAsync, "int*"), IAsync) 
        Rewind() => (ComCall(15, this, "ptr*", IAsync:=this.__Media.IBase()), this.__Media.WaitForAsync(&IAsync, "int*"), IAsync) 
        SkipNext() => (ComCall(16, this, "ptr*", IAsync:=this.__Media.IBase()), this.__Media.WaitForAsync(&IAsync, "int*"), IAsync) 
        SkipPrevious() => (ComCall(17, this, "ptr*", IAsync:=this.__Media.IBase()), this.__Media.WaitForAsync(&IAsync, "int*"), IAsync) 
        ChangeChannelUp() => (ComCall(18, this, "ptr*", IAsync:=this.__Media.IBase()), this.__Media.WaitForAsync(&IAsync, "int*"), IAsync) 
        ChangeChannelDown() => (ComCall(19, this, "ptr*", IAsync:=this.__Media.IBase()), this.__Media.WaitForAsync(&IAsync, "int*"), IAsync) 
        TogglePlayPause() => (ComCall(20, this, "ptr*", IAsync:=this.__Media.IBase()), this.__Media.WaitForAsync(&IAsync, "int*"), IAsync) 
        /**
         * Specifies the auto repeat mode for media playback
         * @param mode 
         * 0 = No repeating.
         * 1 = Repeat the current track.
         * 2 = Repeat the current list of tracks.
         * @returns {Boolean} 
         */
        ChangeAutoRepeatMode(mode) => (ComCall(21, this, "int", mode, "ptr*", IAsync:=this.__Media.IBase()), this.__Media.WaitForAsync(&IAsync, "int*"), IAsync) 
        /**
         * Attempts to change the playback rate on the session to the requested value
         * @param rate The requested playback rate to change to
         * @returns {Boolean} 
         */
        ChangePlaybackRate(rate) => (ComCall(22, this, "double", rate, "ptr*", IAsync:=this.__Media.IBase()), this.__Media.WaitForAsync(&IAsync, "int*"), IAsync) 
        /**
         * Attempts to change whether the session is actively shuffling or not.
         * @param state The requested shuffle state to switch to.
         * @returns {Boolean} 
         */
        ChangeShuffleActive(state) => (ComCall(23, this, "int", !!state, "ptr*", IAsync:=this.__Media.IBase()), this.__Media.WaitForAsync(&IAsync, "int*"), IAsync)
        /**
         * Attempts to change the playback position on the session to the specified time, in seconds.
         * @param pos The requested playback position to seek to, specified in seconds.
         * @returns {Boolean} 
         */
        ChangePlaybackPosition(pos) => (ComCall(24, this, "int", pos*10000000, "ptr*", IAsync:=this.__Media.IBase()), this.__Media.WaitForAsync(&IAsync, "int*"), IAsync) 
    
        AddTimelinePropertiesChangedEvent(funcObj) {
            local handler := this.__Media.CreateEventHandler(funcObj, this.__Media.IID_ITypedEventHandler_TimelinePropertiesChangedEvent), token
            ComCall(25, this, "ptr", handler.ptr, "int64*", &token:=0)
            handler.token := token, handler.Session := this, handler.DefineProp("Remove", {Call:((this) => this.HasOwnProp("token") ? ComCall(26, this.Session, "int64", this.token) : 0)})
            return handler
        }

        AddPlaybackInfoChangedEvent(funcObj) {
            local handler := this.__Media.CreateEventHandler(funcObj, this.__Media.IID_ITypedEventHandler_PlaybackInfoChangedEvent), token
            ComCall(27, this, "ptr", handler.ptr, "int64*", &token:=0)
            handler.token := token, handler.Session := this, handler.DefineProp("Remove", {Call:((this) => this.HasOwnProp("token") ? ComCall(28, this.Session, "int64", this.token) : 0)})
            return handler
        }

        AddMediaPropertiesChangedEvent(funcObj) {
            local handler := this.__Media.CreateEventHandler(funcObj, this.__Media.IID_ITypedEventHandler_MediaPropertiesChangedEvent), token
            ComCall(29, this, "ptr", handler.ptr, "int64*", &token:=0)
            handler.token := token, handler.Session := this, handler.DefineProp("Remove", {Call:((this) => this.HasOwnProp("token") ? ComCall(30, this.Session, "int64", this.token) : 0)})
            return handler
        }
    }

    ; Gets the current session. This is the session the system believes the user would most likely want to control.
    static GetCurrentSession() {
        ComCall(6, this.GlobalSystemMediaTransportControlsSessionManager, "ptr*", GlobalSystemMediaTransportControlsSession:=this.Session()) ; GlobalSystemMediaTransportControlsSessionManager.GetCurrentSession
        if !GlobalSystemMediaTransportControlsSession.ptr
            throw Error("No active sessions found", -1)
        return GlobalSystemMediaTransportControlsSession
    }

    ; Gets all of the available sessions.
    static GetSessions() {
        local sessions := [], count
        ComCall(7, this.GlobalSystemMediaTransportControlsSessionManager, "ptr*", IGlobalSystemMediaTransportControlsSessionList:=this.IBase())
        ComCall(7, IGlobalSystemMediaTransportControlsSessionList, "int*", &count:=0)
        Loop count {
            ComCall(6, IGlobalSystemMediaTransportControlsSessionList, "int", A_index-1, "ptr*", session:=this.Session())
            sessions.Push(session)
        }
        return sessions
    }

    static AddCurrentSessionChangedEvent(funcObj) {
        local handler := this.CreateEventHandler(funcObj, this.IID_ITypedEventHandler_CurrentSessionChangedEvent), token
        ComCall(8, this.GlobalSystemMediaTransportControlsSessionManager, "ptr", handler.ptr, "int64*", &token:=0)
        handler.token := token, handler.DefineProp("Remove", {Call:((this) => this.HasOwnProp("token") ? ComCall(9, this.__Media.GlobalSystemMediaTransportControlsSessionManager, "int64", this.token) : 0)})
        return handler
    }

    static AddSessionsChangedEvent(funcObj) {
        local handler := this.CreateEventHandler(funcObj, this.IID_ITypedEventHandler_SessionsChangedEvent), token
        ComCall(10, this.GlobalSystemMediaTransportControlsSessionManager, "ptr", handler.ptr, "int64*", &token:=0)
        handler.token := token, handler.DefineProp("Remove", {Call:((this) => this.HasOwnProp("token") ? ComCall(11, this.__Media.GlobalSystemMediaTransportControlsSessionManager, "int64", this.token) : 0)})
        return handler
    }

    ;; Only internal methods ahead

    static VectorToArray(IVector, t:="ptr*") {
        local arr := [], count
        ComCall(7, IVector, "int*", &count:=0)
        if IsObject(t) {
            Loop count
                arr.Push((ComCall(6, IVector, "int", A_Index-1, "ptr*", val:=t()), val))
        } else {
            Loop count
                arr.Push((ComCall(6, IVector, "int", A_Index-1, t, val), val))
        }
        return arr
    }

    class Enumeration {
        __Item[param] {
            get {
                local k, v
                for k, v in this.OwnProps()
                    if v = param
                        return k
                throw UnsetItemError("Property item `"" param "`" not found!", -2)
            }
        }
    }

    class IBase {
        __New(ptr?) {
            if IsSet(ptr) && !ptr
                throw ValueError('Invalid IUnknown interface pointer', -2, this.__Class)
            this.DefineProp("ptr", {Value:ptr ?? 0})
        }
        __Delete() => this.ptr ? ObjRelease(this.ptr) : 0
    }

    class IClosable {
        __New(ptr?) {
            if IsSet(ptr) && !ptr
                throw ValueError('Invalid IUnknown interface pointer', -2, this.__Class)
            this.DefineProp("ptr", {Value:ptr ?? 0})
        }
        __Delete() {
            if this.ptr {
                IClosable := ComObjQuery(this.ptr, "{30D5A829-7FA4-4026-83BB-D75BAE4EA99E}")
                ComCall(6, IClosable) ; IClosable_Close
                ObjRelease(this.ptr)
             }
        }
    }

    static CreateClass(str, interface?) {
        local hString := this.HString(str), result
        if !IsSet(interface) {
            result := DllCall("Combase.dll\RoActivateInstance", "ptr", hString, "ptr*", cls:=this.IBase(), "uint")
        } else {
            GUID := this.CLSIDFromString(interface)
            result := DllCall("Combase.dll\RoGetActivationFactory", "ptr", hString, "ptr", GUID, "ptr*", cls:=this.IBase(), "uint")
        }
        if (result != 0) {
            if (result = 0x80004002)
                throw Error("No such interface supported", -1, interface)
            else if (result = 0x80040154)
                throw Error("Class not registered", -1)
            else
                throw Error(result)
        }
        return cls
    }

    class EventHandler {
        Invoke(pSelf, pSender, pArgs) {
            if this.IID = this.__Media.IID_ITypedEventHandler_MediaPropertiesChangedEvent || this.IID = this.__Media.IID_ITypedEventHandler_PlaybackInfoChangedEvent || this.IID = this.__Media.IID_ITypedEventHandler_TimelinePropertiesChangedEvent
                ObjAddRef(pSender), ObjAddRef(pArgs), SetTimer(this.EventHandler.Bind(this.__Media.Session(pSender), this.__Media.IBase(pArgs)), -1)
            else
                ObjAddRef(pSender), ObjAddRef(pArgs), SetTimer(this.EventHandler.Bind(this.__Media.IBase(pSender), this.__Media.IBase(pArgs)), -1)
            return 0
        }
        Remove() { ; Called on __Delete, but defined when an event is registered
        }
    }

    static CreateEventHandler(funcObj, iid) {
        local buf, handler, cR, cAF, cQI, cF
        if funcObj is String
            try funcObj := %funcObj%
        if !HasMethod(funcObj, "Call")
            throw TypeError("Invalid function provided", -2)
    
        buf := Buffer(A_PtrSize * 6), handler := this.EventHandler(), handler.IID := iid, handler.__Media := this, handler.EventHandler := funcObj, handler.Buffer := buf, handler.Ptr := buf.ptr, handlerFunc := handler.Invoke
        /**
         * Creates a "new COM object":
         * typedef struct Object {
         *  vtbl* vtbl;
         *  Object* hander; // the ref count of the handler gets increased keeping track of event handler lifetime
         * }
         * Where vtbl contains QueryInterface, AddRef, Release, and Invoke
         */
        NumPut("ptr", buf.Ptr + 2*A_PtrSize, "ptr", ObjPtr(handler), "ptr", cQI:=CallbackCreate(QueryInterface,, 3), "ptr", cAF:=CallbackCreate(AddRef,, 1), "ptr", cR:=CallbackCreate(Release,, 1), "ptr", cF:=CallbackCreate(handlerFunc.Bind(handler),, 3), buf)
        ObjRelease(ObjPtr(handler)) ; CallbackCreate binds "handler" to itself, so decrease ref count by 1 to allow it to be released, then inside __Delete add it back before CallbackFree
        handler.DefineProp("__Delete", { call: (this, *) => (this.__Media.RegisteredEvents.Delete(this.ptr), ObjAddRef(ObjPtr(this)), CallbackFree(cQI), CallbackFree(cAF), CallbackFree(cR), CallbackFree(cF), this.Remove()) })
        this.RegisteredEvents[buf.Ptr] := iid
        return handler
    
        QueryInterface(pSelf, pRIID, pObj){ ; Credit: https://github.com/neptercn/UIAutomation/blob/master/UIA.ahk
            DllCall("ole32\StringFromIID","ptr",pRIID,"wstr*",&str)
            return (str="{00000000-0000-0000-C000-000000000046}")||(this.RegisteredEvents.Has(pSelf) && str=this.RegisteredEvents[pSelf])?(NumPut("ptr",pSelf,pObj), ObjAddRef(pSelf))*0:0x80004002 ; E_NOINTERFACE
        }
        AddRef(pSelf) => ObjAddRef(NumGet(pSelf, A_PtrSize, "ptr"))
        Release(pSelf) => ObjRelease(NumGet(pSelf, A_PtrSize, "ptr"))
    }

    class HString {
        static Create(str) => (DllCall("Combase.dll\WindowsCreateString", "wstr", str, "uint", StrLen(str), "ptr*", &hString:=0), hString)
        static Delete(hString) => DllCall("Combase.dll\WindowsDeleteString", "ptr", hString)
        __New(str?) => this.DefineProp("ptr", {value:IsSet(str) ? (DllCall("Combase.dll\WindowsCreateString", "wstr", str, "uint", StrLen(str), "ptr*", &hString:=0), hString) : 0})
        __Item[*] => (buf := DllCall("Combase.dll\WindowsGetStringRawBuffer", "ptr", this, "uint*", &length:=0, "ptr"), StrGet(buf, "UTF-16"))
        __Delete() {
            if this.ptr
                DllCall("Combase.dll\WindowsDeleteString", "ptr", this.ptr)
        }
    }
    
    static WaitForAsync(&obj, retType?) {
        local AsyncInfo := ComObjQuery(obj, this.IID_IAsyncInfo), status, ErrorCode
        Loop {
            ComCall(7, AsyncInfo, "uint*", &status:=0)   ; IAsyncInfo.Status
            if (status != 0) {
                if (status != 1) {
                    ComCall(8, ASyncInfo, "uint*", &ErrorCode:=0)   ; IAsyncInfo.ErrorCode
                    throw Error("AsyncInfo failed with status error " ErrorCode, -1)
                }
             break
          }
          Sleep 10
        }
        IsSet(retType) ? ComCall(8, obj, retType, &ObjectResult:=0) : ComCall(8, obj, "ptr*", ObjectResult:=this.IBase())   ; GetResults
        ComCall(10, AsyncInfo) ; IAsyncInfo_Close
        obj := ObjectResult
    }

    static CloseIClosable(pClosable) {
        static IClosable := "{30D5A829-7FA4-4026-83BB-D75BAE4EA99E}"
        local Close := ComObjQuery(pClosable, IClosable)
        ComCall(6, Close)   ; Close
        if !IsObject(pClosable)
            ObjRelease(pClosable)
    }

    static CLSIDFromString(IID) {
        local CLSID := Buffer(16), res
        if res := DllCall("ole32\CLSIDFromString", "WStr", IID, "Ptr", CLSID, "UInt")
           throw Error("CLSIDFromString failed. Error: " . Format("{:#x}", res))
        Return CLSID
    }
}