#include ..\Lib\Misc.ahk

; ----------------- Range ----------------------

; Loop forwards, equivalent to Loop 10
result := ""
for v in Range(10)
    result .= v "`n"
MsgBox(result)

; Loop backwards, equivalent to Range(1,10,-1)
result := ""
for v in Range(10,1)
    result .= v "`n"
MsgBox(result)

; Loop forwards, step 2
result := ""
for v in Range(-10,10,2)
    result .= v "`n"
MsgBox(result)

; Nested looping
result := ""
for v in Range(3)
    for k in Range(5,1)
        result .= v " " k "`n"
MsgBox(result)
