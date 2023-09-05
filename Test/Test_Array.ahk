#include "..\Lib\Array.ahk"
#Include "..\Lib\DUnit.ahk"

class ArrayTestSuite {
    static Fail() {
        throw Error()
    }
    
    Test_Slice() {
        DUnit.Equal([1].Slice(2), [])
        DUnit.Equal([1,2,3,4,5].Slice(2), [2,3,4,5])
    }
    Test_Swap() {
        DUnit.Equal([1,2].Swap(1,2), [2,1])
        DUnit.Throws(Array2.Swap.Bind([], 1,3))
    }
    Test_Map() {
        DUnit.Equal([].Map(a => a+1), [])
        DUnit.Equal([1,2,3].Map(a => a+1), [2,3,4])
        DUnit.Equal([1,,3].Map((a?) => (a ?? 0)+1), [2,1,4])
        DUnit.Equal([1,2,3,4,5].Map((a,b) => a+b, [0,1,3,5,7]), [1,3,6,9,12])
        DUnit.Equal([1,,3,4].Map((a:=0,b:=0) => a+b, [0,1,3,,7]), [1,1,6,4])
    }
    Test_ForEach() {
        DUnit.Equal([].ForEach(ForEachCallback), [])
        DUnit.Equal([1,2,3].ForEach(ForEachCallback), [2,3,4])
        ForEachCallback(val, index, arr) {
            arr[index] := val+1
        }
    }
    Test_Filter() {
        DUnit.Equal([].Filter(IsInteger), [])
        DUnit.Equal([1,'two','three',4,5].Filter(IsInteger), [1,4,5])
    }
    Test_Reduce() {
        DUnit.Throws(Array2.Reduce.Bind([1,2], 0), "ValueError")
        DUnit.Equal([].Reduce((a,b) => (a+b)), '')
        DUnit.Equal([1,2,3,4,5].Reduce((a,b) => (a+b)), 15)
    }
    Test_IndexOf() {
        DUnit.Equal([].IndexOf(2), 0)
        DUnit.Equal([1,2,3].IndexOf(2), 2)
        DUnit.Equal([1,2,3].IndexOf(2,3), 0)
        DUnit.Equal([1,2,3,4,2,1].IndexOf(2,3), 5)
    }
    Test_Find() {
        DUnit.Equal([1,3,5].Find((v) => (Mod(v,2) == 0)), 0)
        DUnit.Equal([1,2,3,4,5].Find((v) => (Mod(v,2) == 0)), 2)
        _ := [1,2,3,4,5].Find((v) => (Mod(v,2) == 0), &val, 3)
        DUnit.Equal(val, 4)
    }
    Test_Reverse() {
        DUnit.Equal([].Reverse(), [])
        DUnit.Equal([1].Reverse(), [1])
        DUnit.Equal([1,2].Reverse(), [2,1])
        DUnit.Equal([1,2,"3","b"].Reverse(), ['b','3',2,1])
    }
    Test_Count() {
        DUnit.Equal([].Count(1), 0)
        DUnit.Equal([1,2,2,1,1].Count(1), 3)
        DUnit.Equal([1,2,2,1,1].Count((a) => (Mod(a,2) == 0)), 2)
    }
    Test_Sort() {
        DUnit.Equal([].Sort(), [])
        DUnit.Equal([1].Sort(), [1])
        DUnit.Equal([4,1,3,2].Sort(), [1,2,3,4])
        DUnit.Equal([4,1,3,2].Sort("COn"), [1, 2, 3, 4])
        DUnit.Throws(ObjBindMethod(["a",1,3,2], "Sort")) ; Only numeric values by default
        DUnit.Throws(ObjBindMethod(["a",1,3,2], "Sort", "X")) ; Invalid option
        DUnit.Equal(["a", 2, 1.2, 1.22, 1.20].Sort("C"), [1.2, 1.2, 1.22, 2, 'a'])
        DUnit.Equal(["c", "b", "a", "C", "F", "A"].Sort("C"), ['A', 'C', 'F', 'a', 'b', 'c'])
        arr := [1,2,3,4,5]
        firstProbabilities := [0,0,0,0,0], lastProbabilities := [0,0,0,0,0]
        Loop 1000 {
            arr.Sort("Random")
            firstProbabilities[arr[1]] += 1
            lastProbabilities[arr[arr.length]] += 1
        }
        for v in firstProbabilities
            DUnit.Assert(v > 150, "Sort Random might not be random, try running again")
        for v in lastProbabilities
            DUnit.Assert(v > 150, "Sort Random might not be random, try running again")

        myImmovables:=[]
        myImmovables.push({town: "New York", size: "60", price: 400000, balcony: 1})
        myImmovables.push({town: "Berlin", size: "45", price: 230000, balcony: 1})
        myImmovables.push({town: "Moscow", size: "80", price: 350000, balcony: 0})
        myImmovables.push({town: "Tokyo", size: "90", price: 600000, balcony: 2})
        myImmovables.push({town: "Palma de Mallorca", size: "250", price: 1100000, balcony: 3})
        DUnit.Equal(myImmovables.Sort("N R", "size"), [{balcony:3, price:1100000, size:'250', town:'Palma de Mallorca'}, {balcony:2, price:600000, size:'90', town:'Tokyo'}, {balcony:0, price:350000, size:'80', town:'Moscow'}, {balcony:1, price:400000, size:'60', town:'New York'}, {balcony:1, price:230000, size:'45', town:'Berlin'}])
    }
    Test_Shuffle() {
        DUnit.Equal([].Shuffle(), [])
        DUnit.Equal([1].Shuffle(), [1])
        DUnit.Equal([1,2].Shuffle().Length, 2)
    }
    Test_Join() {
        DUnit.Equal([].Join(), "")
        DUnit.Equal([1,2,3].Join(), "1,2,3")
        DUnit.Equal([1,2,3].Join(""), "123")
    }
    Test_Flat() {
        DUnit.Equal([].Flat(), [])
        DUnit.Equal([1,[2,[3]]].Flat(), [1,2,3])
    }
    Test_Extend() {
        DUnit.Equal([].Extend([]), [])
        DUnit.Throws(Array2.Extend.Bind([], 0), "ValueError")
        DUnit.Equal([,[2]].Extend([3]), [,[2],3])
    }
}