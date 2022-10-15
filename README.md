# AHK-v2-libraries
# Useful libraries for AHK v2

## Misc.ahk
Implements useful miscellaneous functions

### Range
Allows looping from start to end with step.
```
Range(stop)
Range(start, stop [, step ])
```
Usage: `for v in Range(2,10)` -> loops from 2 to 10
`for v in Range(10,1,-1)` -> loops from 10 to 1 backwards

### RegExMatchAll
Returns all RegExMatch results for NeedleRegEx in Haystack in an array: [RegExMatchInfo1, RegExMatchInfo2, ...]
```
RegExMatchAll(Haystack, NeedleRegEx, StartingPosition := 1)
```

### Swap
Swaps the values of two variables
```
Swap(&a, &b)
```

### Print
Prints the formatted value of a variable (number, string, array, map, object)
```
Print(value?, func?, newline?)
```

## String.ahk
Implements useful string functions and lets strings be treated as objects

Native AHK functions as methods:
```
String.ToUpper()
      .ToLower()
      .ToTitle()
      .Split([Delimiters, OmitChars, MaxParts])
      .Replace(Needle [, ReplaceText, CaseSense, &OutputVarCount, Limit])
      .Trim([OmitChars])
      .LTrim([OmitChars])
      .RTrim([OmitChars])
      .Compare(comparison [, CaseSense])
      .Sort([, Options, Function])
      .Find(Needle [, CaseSense, StartingPos, Occurrence])
      .SplitPath() => returns object with keys FileName, Dir, Ext, NameNoExt, Drive
	  .RegExMatch(needleRegex, &match?, startingPos?)
	  .RegExReplace(needle, replacement?, &count?, limit?, startingPos?)
```

```
String[n] => gets nth character
String[i,j] => substring from i to j
String.Length
String.Count(searchFor)
String.Insert(insert, into [, pos])
String.Delete(string [, start, length])
String.Overwrite(overwrite, into [, pos])
String.Repeat(count)
Delimeter.Concat(words*)

String.LineWrap([column:=56, indentChar:=""])
String.WordWrap([column:=56, indentChar:=""])
String.ReadLine(line [, delim:="`n", exclude:="`r"])
String.DeleteLine(line [, delim:="`n", exclude:="`r"])
String.InsertLine(insert, into, line [, delim:="`n", exclude:="`r"])

String.Reverse()
String.Contains(needle1 [, needle2, needle3...])
String.RemoveDuplicates([delim:="`n"])
String.LPad(count)
String.RPad(count)

String.Center([fill:=" ", symFill:=0, delim:="`n", exclude:="`r", width])
String.Right([fill:=" ", delim:="`n", exclude:="`r"])
```

## Array.ahk
Implements useful array functions

```
Array.Slice(start:=1, end:=0, step:=1)  => Returns a section of the array from 'start' to 'end', 
    optionally skipping elements with 'step'.
Array.Swap(a, b)                        => Swaps elements at indexes a and b.
Array.Map(func)                         => Applies a function to each element in the array.
Array.Filter(func)                      => Keeps only values that satisfy the provided function
Array.Reduce(func, initialValue?)       => Applies a function cumulatively to all the values in 
    the array, with an optional initial value.
Array.IndexOf(value, start:=1)          => Finds a value in the array and returns its index.
Array.Find(func, &match?, start:=1)     => Finds a value satisfying the provided function and
    returns the index. match will be set to the found value. 
Array.Reverse()                         => Reverses the array.
Array.Count(value)                      => Counts the number of occurrences of a value.
Array.Sort(Key?, Options?, Callback?)   => Sorts an array, optionally by object values.
Array.Join(delim:=",")                  => Joins all the elements to a string using the provided delimiter.
Array.Shuffle()                         => Randomizes the array.
Array.Flat()                            => Turns a nested array into a one-level array.
Array.Extend(arr)                       => Adds the contents of another array to the end of this one.
```

## Acc.ahk

Accessibility library for AHK v2

Acc.ahk examples are available at the Acc v2 GitHub: https://github.com/Descolada/Acc-v2

Short introduction:
      Acc v2 in not a port of v1, but instead a complete redesign to incorporate more object-oriented approaches. 

      Notable changes:
      1) All Acc elements are now array-like objects, where the "Length" property contains the number of children, any nth children can be accessed with element[n], and children can be iterated over with for loops.
      2) Acc main functions are contained in the global Acc object
      3) Element methods are contained inside element objects
      4) Element properties can be used without the "acc" prefix
      5) ChildIds have been removed (are handled in the backend), but can be accessed through 
      el.ChildId
      6) Additional methods have been added for elements, such as FindFirst, FindAll, Click
      7) Acc constants are included in the Acc object
      8) AccViewer is built into the library: when ran directly the AccViewer will show, when included
      in another script then it won't show (but can be accessed by calling Acc.Viewer())

Acc constants/properties:
```
Constants can be accessed as properties (eg Acc.OBJID.CARET), or the property name can be
accessed by getting as an item (eg Acc.OBJID[0xFFFFFFF8])

OBJID
STATE
ROLE
NAVDIR
SELECTIONFLAG
EVENT

Explanations for the constants are available in Microsoft documentation:
https://docs.microsoft.com/en-us/windows/win32/winauto/constants-and-enumerated-types
```

Acc methods:
```
ObjectFromPoint(x:=unset, y:=unset, &idChild := "", activateChromium := True)
    Gets an Acc element from screen coordinates X and Y (NOT relative to the active window).
ObjectFromWindow(hWnd:="A", idObject := 0, activateChromium := True)
    Gets an Acc element from a WinTitle, by default the active window. 
    Additionally idObject can be specified from Acc.OBJID constants (eg to get the Caret location).
GetRootElement()
    Gets the Acc element for the Desktop
ActivateChromiumAccessibility(hWnd) 
    Sends the WM_GETOBJECT message to the Chromium document element and waits for the 
    app to be accessible to Acc. This is called when ObjectFromPoint or ObjectFromWindow 
    activateChromium flag is set to True. A small performance increase may be gotten 
    if that flag is set to False when it is not needed.
RegisterWinEvent(event, callback) 
    Registers an event from Acc.EVENT to a callback function and returns a new object
        containing the WinEventHook
    The callback function needs to have three arguments: 
        CallbackFunction(oAcc, Event, EventTime)
    Unhooking of the event handler will happen once the returned object is destroyed
    (either when overwritten by a constant, or when the script closes).

Legacy methods:
SetWinEventHook(eventMin, eventMax, pCallback)
UnhookWinEvent(hHook)
ObjectFromPath(ChildPath, hWnd:="A")    => Same as ObjectFromWindow[comma-separated path]
GetRoleText(nRole)                      => Same as element.RoleText
GetStateText(nState)                    => Same as element.StateText
Query(pAcc)                             => For internal use
```

IAccessible element properties:
```
Element[n]          => Gets the nth element. Multiple of these can be used like a path:
                        Element[4,1,4] will select 4th childs 1st childs 4th child
                        Conditions (see ValidateCondition) are supported: 
                        Element[4,{Name:"Something"}] will select the fourth childs first child matching the name "Something"
                        Conditions also accept an index (or i) parameter to select from multiple similar elements
                        Element[{Name:"Something", i:3}] selects the third element of elements with name "Something"
                        Negative index will select from the last element
                        Element[{Name:"Something", i:-1}] selects the last element of elements with name "Something"
                        Since index/i needs to be a key-value pair, then to use it with an "or" condition
                        it must be inside an object ("and" condition), for example with key "or":
                        Element[{or:[{Name:"Something"},{Name:"Something else"}], i:2}]
Name                => Gets or sets the name. All objects support getting this property.
Value               => Gets or sets the value. Not all objects have a value.
Role                => Gets the Role of the specified object in integer form. All objects support this property.
RoleText            => Role converted into text form. All objects support this property.
Help                => Retrieves the Help property string of an object. Not all objects support this property.
KeyboardShortcut    => Retrieves the specified object's shortcut key or access key. Not all objects support this property.
State               => Retrieves the current state in integer form. All objects support this property.
StateText           => State converted into text form
Description         => Retrieves a string that describes the visual appearance of the specified object. Not all objects have a description.
DefaultAction       => Retrieves a string that indicates the object's default action. Not all objects have a default action.
Focus               => Returns the focused child element (or itself).
                        If no child is focused, an error is thrown
Selection           => Retrieves the selected children of this object. All objects that support selection must support this property.
Parent              => Returns the parent element. All objects support this property.
IsChild             => Checks whether the current element is of child type
Length              => Returns the number of children the element has
Location            => Returns the object's current screen location in an object {x,y,w,h}
Children            => Returns all children as an array (usually not required)
Exists              => Checks whether the element is still alive and accessible
ControlID           => ID (hwnd) of the control associated with the element
WinID               => ID (hwnd) of the window the element belongs to
oAcc                => ComObject of the underlying IAccessible
childId             => childId of the underlying IAccessible
```

IAccessible element methods:
```
Select(flags)
    Modifies the selection or moves the keyboard focus of the specified object. 
    flags can be any of the SELECTIONFLAG constants
DoDefaultAction()
    Performs the specified object's default action. Not all objects have a default action.
GetNthChild(n)
    This is equal to element[n]
GetLocation(relativeTo:="")
    Returns an object containing the x, y coordinates and width and height: {x:x coordinate, y:y coordinate, w:width, h:height}. 
    relativeTo can be client, window or screen, default is A_CoordModeMouse.
IsEqual(oCompare)
    Checks whether the element is equal to another element (oCompare)
FindFirst(condition, scope:=4) 
    Finds the first element matching the condition (see description under ValidateCondition)
    Scope is the search scope: 1=element itself; 2=direct children; 4=descendants (including children of children)
The scope is additive: 3=element itself and direct children.
    The returned element also has the "Path" property with the found elements path

    FindFirst conditions also accept an index (or i) parameter to search for i-th element:
FindFirst({Name:"Something", i:3}) finds the third element with name "Something"
    Negative index reverses the search direction:
FindFirst({Name:"Something", i:-1}) finds the last element with name "Something"
    Since index/i needs to be a key-value pair, then to use it with an "or" condition
    it must be inside an object ("and" condition), for example with key "or":
FindFirst({or:[{Name:"Something"}, {Name:"Something else"}], index:2})
FindAll(condition, scope:=4)
    Returns an array of elements matching the condition (see description under ValidateCondition)
    The returned elements also have the "Path" property with the found elements path
WaitElementExist(conditionOrPath, scope:=4, timeOut:=-1)
    Waits an element exist that matches a condition or a path. 
    Timeout less than 1 waits indefinitely, otherwise is the wait time in milliseconds
    A timeout throws an error, otherwise the matching element is returned.
Normalize(condition)
    Checks whether the current element or any of its ancestors match the condition, 
    and returns that element. If no element is found, an error is thrown.
ValidateCondition(condition)
    Checks whether the element matches a provided condition.
    Everything inside {} is an "and" condition, or a singular condition with options
    Everything inside [] is an "or" condition
    "not" key creates a not condition
    "matchmode" key (short form: "mm") defines the MatchMode: 1=must start with; 2=can contain anywhere in string; 3=exact match; RegEx
    "casesensitive" key (short form: "cs") defines case sensitivity: True=case sensitive; False=case insensitive
    Any other key (but usually "or") can be used to use "or" condition inside "and" condition.

    {Name:"Something"} => Name must match "Something" (case sensitive)
    {Name:"Something", matchmode:2, casesensitive:False} => Name must contain "Something" anywhere inside the Name, case insensitive
    {Name:"Something", RoleText:"something else"} => Name must match "Something" and RoleText must match "something else"
    [{Name:"Something", Role:42}, {Name:"Something2", RoleText:"something else"}] => Name=="Something" and Role==42 OR Name=="Something2" and RoleText=="something else"
    {Name:"Something", not:[{RoleText:"something", mm:2}, {RoleText:"something else", cs:1}]} => Name must match "something" and RoleText cannot match "something" (with matchmode=2) nor "something else" (casesensitive matching)
    {or:[{Name:"Something"},{Name:"Something else"}], or2:[{Role:20},{Role:42}]}
Dump(scope:=1)
    Outputs relevant information about the element (Name, Value, Location etc)
    Scope is the search scope: 1=element itself; 2=direct children; 4=descendants (including children of children); 7=whole subtree (including element)
        The scope is additive: 3=element itself and direct children.
DumpAll()
    Outputs relevant information about the element and all descendants of the element. This is equivalent to Dump(7)
Highlight(showTime:=unset, color:="Red", d:=2)
    Highlights the element for a chosen period of time
    Possible showTime values:
        Unset: removes the highlighting
        0: Indefinite highlighting
        Positive integer (eg 2000): will highlight and pause for the specified amount of time in ms
        Negative integer: will highlight for the specified amount of time in ms, but script execution will continue
    color can be any of the Color names or RGB values
    d sets the border width
Click(WhichButton:="left", ClickCount:=1, DownOrUp:="", Relative:="", NoActivate:=False)
    Click the center of the element.
    If WhichButton is a number, then Sleep will be called with that number. 
      Eg Click(200) will sleep 200ms after clicking
    If ClickCount is a number >=10, then Sleep will be called with that number. To click 10+ times and sleep after, specify "ClickCount SleepTime". Ex: Click("left", 200) will sleep 200ms after clicking. 
      Ex: Click("left", "20 200") will left-click 20 times and then sleep 200ms.
    If Relative is "Rel" or "Relative" then X and Y coordinates are treated as offsets from the current mouse position. Otherwise it expects offset values for both X and Y (eg "-5 10" would offset X by -5 and Y by +10).
    NoActivate will cause the window not to be brought to focus before clicking if the clickable point is not visible on the screen.
ControlClick(WhichButton:="left", ClickCount:=1, Options:="")
    ControlClicks the element after getting relative coordinates with GetLocation("client"). 
    If WhichButton is a number, then a Sleep will be called afterwards. Ex: ControlClick(200) will sleep 200ms after clicking. Same for ControlClick("ahk_id 12345", 200)
Navigate(navDir)
    Navigates in one of the directions specified by Acc.NAVDIR constants. Not all elements implement this method. 
HitTest(x, y)
    Retrieves the child element or child object that is displayed at a specific point on the screen.
    This shouldn't be used, since Acc.ObjectFromPoint uses this internally
```
