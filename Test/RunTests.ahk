#include ..\Lib\DUnit.ahk
#include Test_String.ahk
#include Test_Array.ahk
#include Test_Misc.ahk
#include Test_Map.ahk
#include Test_DPI.ahk

;DUnit("C", DPITestSuite)
DUnit("C", StringTestSuite, ArrayTestSuite, MapTestSuite, MiscTestSuite)