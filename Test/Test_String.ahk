#include "..\Lib\String.ahk"

class StringTestSuite {
    static Fail() {
        throw Error()
    }

    Test_Substring() {
        DUnit.Equal(""[1], "")
        DUnit.Equal("abcd"[2,3], "bc")
        DUnit.Equal("abcd"[-3,-1], "bcd")
    }
    Test___Item() {
        DUnit.Equal("abcd"[2,3], "bc")
        DUnit.Equal("12ab45"[1,3], "12a")
        DUnit.Equal("12ab45"[-1,-3], "54b")
        DUnit.Equal("12ab45"[1,1], "1")
    }
    Test___Enum() {
        res := ""
        for c in "abcd"
            res .= c " "
        DUnit.Equal(res, "a b c d ")
        res := ""
        for i, c in "abcd"
            res .= i ":" c " "
        DUnit.Equal(res, "1:a 2:b 3:c 4:d ")
        res := ""
        for c in ""
            res .= c " "
        DUnit.Equal(res, "")
    }
    Test_Length() {
        DUnit.Equal("".Length, 0)
        DUnit.Equal("abc".Length, 3)
        DUnit.Equal("💩abc".Length, 5)
        DUnit.Equal("💩abc".WLength, 4)
        DUnit.Equal("💩abc".ULength, 4)
        DUnit.Equal("👨‍👩‍👧‍👦".ULength, 1)
        DUnit.Equal("Z͑ͫ̓ͪ̂ͫ̽͏̴̙̤̞͉͚̯̞̠͍A̴̵̜̰͔ͫ͗͢L̠ͨͧͩ͘G̴̻͈͍͔̹̑͗̎̅͛́Ǫ̵̹̻̝̳͂̌̌͘!͖̬̰̙̗̿̋ͥͥ̂ͣ̐́́͜͞".ULength, 6)
        ;DUnit.Equal("👨‍👩‍👧‍👦".WLength, 1)
    }

    Test_ToUpper() {
        DUnit.Equal("abc".ToUpper(), "ABC")
        DUnit.Equal("Abc1 ".ToUpper(), "ABC1 ")
        DUnit.Equal("".ToUpper(), "")
    }
    Test_ToLower() {
        DUnit.Equal("ABC".ToLower(), "abc")
        DUnit.Equal("AbC1 ".ToLower(), "abc1 ")
        DUnit.Equal("".ToLower(), "")
    }
    Test_ToTitle() {
        DUnit.Equal("abc".ToTitle(), "Abc")
        DUnit.Equal("f-sharp".ToTitle(), "F-sharp")
        DUnit.Equal("This is a 11-test.".ToTitle(), "This Is A 11-Test.")
        DUnit.Equal("".ToTitle(), "")
    }
    Test_Split() {
        DUnit.Equal("abc,def,ghi".Split(","), ["abc","def","ghi"])
        DUnit.Equal("💩💩emoji".Split("💩em"), ["💩", "oji"])
        ;OutputDebug(SubStr("💩", 1,1))
        ;DUnit.Equal("abc💩def💩ghi".Split("💩"), ["abc","def","ghi"])
        DUnit.Equal("abc,def,N  ghi  n".Split(",", "N n"), ["abc","def","ghi"])
        DUnit.Equal("abc,N def,  nghi  n".Split(","," nN",2), ["abc","def,  nghi"])
    }
    Test_Trim() {
        DUnit.Equal("".Trim(), "")
        DUnit.Equal(" abcd ".Trim(" ad"), "bc")
    }
    Test_LTrim() {
        DUnit.Equal("".LTrim(), "")
        DUnit.Equal(" abcd ".LTrim(" ad"), "bcd ")
    }
    Test_RTrim() {
        DUnit.Equal("".RTrim(), "")
        DUnit.Equal(" abcd ".RTrim(" ad"), " abc")
    }
    Test_Compare() {
        DUnit.Equal("".Compare(""), 0)
        DUnit.Equal("Abc".Compare("abc", 1), -1)
        DUnit.Equal("A10".Compare("A2", "Logical"), 1)
    }
    Test_Format() {
        DUnit.Equal("{2}, {1}!".Format("World", "Hello"), "Hello, World!")
        DUnit.Equal("{:-10}".Format("Left"), "Left      ")
        DUnit.Equal("{:10}".Format("Right"), "     Right")
        DUnit.Equal("{1:#x} {2:X} 0x{3:x}".Format(3735928559, 195948557, 0), "0xdeadbeef BADF00D 0x0")
        DUnit.Equal("{1:0.3f} {1:.10f}".Format(3.141592654), "3.142 3.1415926540")
    }
    Test_Sort() {
        DUnit.Equal("".Sort(), "")
        DUnit.Equal("5,3,7,9,1,13,999,-4".Sort("N D,"), "-4,1,3,5,7,9,13,999")
        DUnit.Equal("5,3,7,9,1,1,13,999,-4".Sort("U D,", (a,b,*) => (a < b ? 1 : a > b ? -1 : 0)), "999,13,9,7,5,3,1,-4")
        DUnit.Equal("A3`nA1`nZ70`nZ070".Sort("CLogical"), "A1`nA3`nZ070`nZ70")
    }
    Test_InStr() {
        DUnit.Equal("".Find("b"), 0)
        DUnit.Equal("abc".Find("b"), 2)
    }
    Test_RegExMatch() {
        DUnit.Equal("abc".RegexMatch("b")[], "b")
        DUnit.Equal("abc".RegexMatchAll("b")[1][], "b")
        DUnit.Equal("abc".RegexMatchAll("b").Length, 1)
        DUnit.Equal("abc".RegexMatchAll("b|c").Length, 2)
    }
    Test_RegExReplace() {
        DUnit.Equal("abc".RegexReplace("b"), "ac")
        DUnit.Equal("abc".RegexReplace(["b"]), "ac")
        DUnit.Equal("abc".RegexReplace(["a", "(c)"], ["", "$1$1"]), "bcc")
    }
    Test_SplitPath() {
        DUnit.Equal("C:\My Documents\Address List.txt".SplitPath(), {FileName: "Address List.txt", Dir: "C:\My Documents", Ext: "txt", NameNoExt: "Address List", Drive: "C:"})
    }
    Test_Replace() {
        ;Replace(Needle [, ReplaceText, CaseSense, &OutputVarCount, Limit])
        DUnit.Equal("ABCabc".Replace("abc", "cba", 1), "ABCcba")
        DUnit.Equal("ABCabc".Replace("abc", "cba", "Off", &count), "cbacba")
        DUnit.Equal(count, 2)
        DUnit.Equal("Num1num2num3num2".Replace("num2", "💩",,,1), "Num1💩num3num2")
    }
    Test_LPad() {
        DUnit.Equal("aaa".LPad("+", -1), "aaa")
        DUnit.Equal("aaa".LPad("+", 5), "+++++aaa")
    }
    Test_RPad() {
        DUnit.Equal("aaa".RPad("+", -1), "aaa")
        DUnit.Equal("aaa".RPad("+", 5), "aaa+++++")
    }
    Test_Count() {
        DUnit.Equal("12234".Count("5"), 0)
        DUnit.Equal("12234".Count("2"), 2)
    }
    Test_Repeat() {
        DUnit.Equal("abc".Repeat(0), "")
        DUnit.Equal("a}".Repeat(1), "a}")
        DUnit.Equal("abc".Repeat(3), "abcabcabc")
    }
    Test_Reverse() {
        DUnit.Equal("".Reverse(), "")
        DUnit.Equal("Olé".Reverse(), "élO")
    }
    Test_WReverse() {
        DUnit.Equal("".WReverse(), "")
        DUnit.Equal("ab`nc1💩".WReverse(), "💩1c`nba")
    }
    Test_Insert() {
        DUnit.Equal("abcdef".Insert("123"), "123abcdef")
        DUnit.Equal("abc".Insert("d", 0), "abcd")
        DUnit.Equal("abc".Insert("d", -1), "abdc")
    }
    Test_Overwrite() {
        DUnit.Equal("aaabbbccc".Overwrite("zzz", 4), "aaazzzccc")
        DUnit.Equal("123bbbccc".Overwrite("zzz", 10), "")
        DUnit.Equal("aaabbbccc".Overwrite("zzz", 0), "aaabbbccczzz")
        DUnit.Equal("aaabbbccc".Overwrite("zzz", -3), "aaabbbzzz")
    }
    Test_Delete() {
        DUnit.Equal("aaabbbccc".Delete(4, 3), "aaaccc")
        DUnit.Equal("123456".Delete(-3, 3), "123")
        DUnit.Equal("aaabbbccc".Delete(-1, 2), "aaabbbcc")
    }
    Test_LineWrap() {
        DUnit.Equal("Apples are a round fruit, usually red".LineWrap(20, "---"), "Apples are a round f`n---ruit, usually red")
    }
    Test_WordWrap() {
        DUnit.Throws(String2.WordWrap.Bind("abc", "a"), "TypeError")
        DUnit.Equal("Apples are a round fruit, usually red.".WordWrap(20, "---"), "Apples are a round`n---fruit, usually`n---red.")
    }
    Test_InsertLine() {
        DUnit.Equal("aaa|ccc|ddd".InsertLine("bbb", 2, "|"), "aaa|bbb|ccc|ddd")
        DUnit.Equal("aaa`n`rbbb`n`rccc".InsertLine("ddd", 0), "aaa`nbbb`nccc`nddd")
        DUnit.Equal("aaa|bbb|ccc".InsertLine("ddd", -1, "|"), "aaa|bbb|ddd|ccc")
        DUnit.Equal("aaa|ccc|ddd".InsertLine("bbb", 5, "|"), "aaa|ccc|ddd||bbb")
    }
    Test_DeleteLine() {
        DUnit.Throws(String2.DeleteLine.Bind("abc", 0, "a"), "ValueError")
        DUnit.Equal("aaa|bbb|777|ccc".DeleteLine(3, "|"), "aaa|bbb|ccc")
        DUnit.Equal("aaa|bbb|777|ccc".DeleteLine(-1, "|"), "aaa|bbb|777")
    }
    Test_ReadLine() {
        DUnit.Throws(String2.ReadLine.Bind("abc", 0, "a"), "ValueError")
        DUnit.Equal("aaa|bbb|ccc|ddd|eee|fff".ReadLine(4, "|"), "ddd")
        DUnit.Equal("aaa|bbb|ccc|ddd|eee|fff".ReadLine(-1, "|"), "fff")
    }
    Test_RemoveDuplicates() {
        DUnit.Equal("aaa|bbb|||ccc||ddd".RemoveDuplicates("|"), "aaa|bbb|ccc|ddd")
        DUnit.Equal("abc\\\cde".RemoveDuplicates("\"), "abc\cde")
        DUnit.Equal("abc`n`ncde".RemoveDuplicates("`n"), "abc`ncde")
        DUnit.Equal("abc(\)}(\)}cde".RemoveDuplicates("(\)}"), "abc(\)}cde")
    }
    Test_Contains() {
        DUnit.True("aaa|bbb|ccc|ddd".Contains("eee", "aaa"))
        DUnit.False("aaa|bbb|ccc|ddd".Contains("eee"))
    }
    Test_Center() {
        DUnit.Equal("".Center(), "")
        DUnit.Equal("aaa`na`naaaaaaaa".Center(), "  aaa`n   a`naaaaaaaa")
        DUnit.Equal("aaa`na`naaaaaaaa".Center(,1), "  aaa   `n   a    `naaaaaaaa")
        DUnit.Equal("aaa`na`naaaaaaaa".Center(,1,,,9), "   aaa   `n    a    `naaaaaaaa ")
    }
    Test_Right() {
        DUnit.Equal("".Right(), "")
        DUnit.Equal("aaa`na`naaaaaaaa".Right(), "     aaa`n       a`naaaaaaaa")
        DUnit.Equal("aaa`na`naaaaaaa".Right(), "    aaa`n      a`naaaaaaa")
    }
    Test_Is() {
        DUnit.True("abc".IsAlnum)
        DUnit.True("abc1".IsAlnum)
        DUnit.False("abc.".IsAlnum)
        DUnit.True("0".IsDigit)
    }
    Test_Concat() {
        DUnit.Equal("|".Concat("111", "222", "333"), "111|222|333")
        DUnit.Equal("d".Concat("ddd", "ddd"), "ddddddd")
        DUnit.Equal("<br>".Concat("break", "br"), "break<br>br")
    }
}