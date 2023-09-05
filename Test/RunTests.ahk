#include ..\Lib\DUnit.ahk
#include Test_String.ahk
#include Test_Array.ahk
#include Test_Misc.ahk
#include Test_Map.ahk

DUnit("C", StringTestSuite, ArrayTestSuite, MapTestSuite, MiscTestSuite)