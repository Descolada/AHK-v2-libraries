#Requires AutoHotkey v2.0 
#include ..\Lib\BufferedHotstrings.ahk

; #MaxThreadsPerHotkey needs to be higher than 1, otherwise some hotstrings might get lost 
; if their activation strings were buffered.
#MaxThreadsPerHotkey 10
; Enable X (execution), B0 (no backspacing) and O (omit end-character) for all hotstrings, which are necessary for this library to work.
; Z option resets the hotstring recognizer after each replacement, as AHK does with auto-replace hotstrings
#Hotstring ZXB0O

; For demonstration purposes lets use SendEvent as the default hotstring mode.
; `#Hotstring SE` won't have the desired effect, because we are not using regular hotstrings.
_HS(, "SE")

; Regular hotstrings only need to be wrapped with _HS. This uses SendEvent with default delay 0.
::fwi::_HS("for your information")
; Regular hotstring arguments can be used; this sets the keydelay to 40ms (this works since we are using SendMode Event)
:K40:afaik::_HS("as far as I know")
; Other hotstring arguments can be used as well such as Text
:T:omg::_HS("oh my god{enter}")
; Backspacing can be limited to n backspaces with Bn
:*:because of it's::_HS("s", "B2")
; ... however that's usually not necessary, because unlike the default implementation, this one backspaces 
; only the non-matching end of the trigger string
:*:thats::_HS("that's")
; To use regular hotstrings without _HS, reverse the global changes locally (X0 disables execute, B enables backspacing, O0 reverts omitting endchar)
:X0BO0:btw::by the way