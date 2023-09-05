#Requires AutoHotkey v2.0

#include "..\Lib\Map.ahk"
#Include "..\Lib\DUnit.ahk"

class MapTestSuite {
    static Fail() {
        throw Error()
    }

    Begin() {
        this.EmptyMap := Map()
        this.Map := Map("a", 1, "b", 2, "c", 3)
    }

    Test_Keys() {
        DUnit.Equal(this.EmptyMap.Keys, [])
        DUnit.Equal(this.Map.Keys, ["a", "b", "c"])
    }
    Test_Values() {
        DUnit.Equal(this.EmptyMap.Values, [])
        DUnit.Equal(this.Map.Values, [1,2,3])
    }
    Test_Map() {
        DUnit.Equal(this.EmptyMap.Map((k,a) => a+1), Map())
        DUnit.Equal(this.Map.Map((k,a) => a+1), Map("a", 2, "b", 3, "c", 4))
        DUnit.Equal(Map("a", 1, "b", 2, "c", 3).Map((k,v1,v2) => v1+v2, Map("a", 2, "b", 2, "c", 2)), Map("a", 3, "b", 4, "c", 5))
    }
    Test_ForEach() {
        DUnit.Equal(this.EmptyMap.ForEach(ForEachCallback), Map())
        DUnit.Equal(this.Map.ForEach(ForEachCallback), Map("a", 2, "b", 3, "c", 4))
        ForEachCallback(val, key, m) {
            m[key] := val+1
        }
    }
    Test_Filter() {
        DUnit.Equal(this.EmptyMap.Filter(IsInteger), Map())
        DUnit.Equal(Map("a", 1, "b", "b", "c", 3, "d", "d").Filter((k,v) => IsInteger(v)), Map("a", 1, "c", 3))
    }
    Test_Find() {
        DUnit.Equal(Map("a", 1, "b", 2, "c", 3).Find((v) => (Mod(v,2) == 0)), "b")
    }
    Test_Count() {
        DUnit.Equal(Map().Count(1), 0)
        DUnit.Equal(Map("a", 1, "b", 1, "c", 2).Count(1), 2)
        DUnit.Equal(Map("a", 1, "b", 1, "c", 2).Count((a) => (Mod(a,2) == 0)), 1)
    }
    Test_Extend() {
        DUnit.Equal(Map("a", 1, "b", 2).Extend(Map("c", 3)), this.Map)
        DUnit.Throws(Array2.Extend.Bind(Map(), 0), "ValueError")
        DUnit.Equal(Map("a", 1, "b", 2).Extend([3]), Map("a", 1, "b", 2, 1, 3))
    }
}