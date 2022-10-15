/*
	Name: Misc.ahk
	Version 0.1 (26.08.22)
	Created: 26.08.22
	Author: Descolada (https://www.autohotkey.com/boards/viewtopic.php?f=83&t=107759)
    Credit: Coco

	Range(stop)						=> Returns an iterable to count from 1..stop
	Range(start, stop [, step])		=> Returns an iterable to count from start to stop with step
	Swap(&a, &b)					=> Swaps the values of a and b
	Print(value?, func?, newline?) 	=> Prints the formatted value of a variable (number, string, array, map, object)
*/

/**
 * Returns a sequence of numbers, starting from 1 by default, 
 * and increments by step 1 (by default), 
 * and stops at a specified end number.
 * Can be converted to an array with the method ToArray()
 * @param start The number to start with, or if 'end' is omitted then the number to end with
 * @param end The number to end with
 * @param step Optional: a number specifying the incrementation. Default is 1.
 * @returns {Iterable}
 * @example 
 * for v in Range(5)
 *     Print(v) ; Outputs "1 2 3 4 5"
 */
class Range {
	__New(start, end?, step:=1) {
		if !step
			throw TypeError("Invalid 'step' parameter")
		if !IsSet(end)
			end := start, start := 1
		if (end < start) && (step > 0)
			step := -step
		this.start := start, this.end := end, this.step := step
	}
	__Enum(varCount) {
		start := this.start - this.step, end := this.end, step := this.step, counter := 0
		EnumElements(&element) {
			start := start + step
			if ((step > 0) && (start > end)) || ((step < 0) && (start < end))
				return false
			element := start
			return true
		}
		EnumIndexAndElements(&index, &element) {
			start := start + step
			if ((step > 0) && (start > end)) || ((step < 0) && (start < end))
				return false
			index := ++counter
			element := start
			return true
		}
		return (varCount = 1) ? EnumElements : EnumIndexAndElements
	}
	/**
	 * Converts the iterable into an array.
	 * @returns {Array}
	 * @example
	 * Range(3).ToArray() ; returns [1,2,3]
	 */
	ToArray() {
		r := []
		for v in this
			r.Push(v)
		return r
	}
}

/**
 * Swaps the values of two variables
 * @param a First variable
 * @param b Second variable
 */
Swap(&a, &b) {
	temp := a
	a := b
	b := temp
}

/**
 * Prints the formatted value of a variable (number, string, object).
 * Leaving all parameters empty will return the current function and newline in an Array: [func, newline]
 * @param value Optional: the variable to print. 
 *     If omitted then new settings (output function and newline) will be set.
 *     If value is an object/class that has a ToString() method, then the result of that will be printed.
 * @param func Optional: the print function to use. Default is OutputDebug.
 *     Not providing a function will cause the Print output to simply be returned as a string.
 * @param newline Optional: the newline character to use (applied to the end of the value). 
 *     Default is newline (`n).
 */
Print(value?, func?, newline?) {
	static p := OutputDebug, nl := "`n"
	if IsSet(func)
		p := func
	if IsSet(newline)
		nl := newline
	if IsSet(value) {
		val := IsObject(value) ? _Print(value) nl : value nl
		return HasMethod(p) ? p(val) : val
	}
	return [p, nl]

	_Print(val?) {
		if !IsSet(val)
			return "unset"
		valType := Type(val)
		switch valType, 0 {
			case "String":
				return "'" val "'"
			case "Integer", "Float":
				return val
			default:
				self := "", iter := "", out := ""
				try self := _Print(val.ToString()) ; if the object has ToString available, print it
				if valType != "Array" { ; enumerate object with key and value pair, except for array
					try {
						enum := val.__Enum(2) 
						while (enum.Call(&val1, &val2))
							iter .= _Print(val1) ":" _Print(val2?) ", "
					}
				}
				if !IsSet(enum) { ; if enumerating with key and value failed, try again with only value
					try {
						enum := val.__Enum(1)
						while (enum.Call(&enumVal))
							iter .= _Print(enumVal?) ", "
					}
				}
				if !IsSet(enum) && (valType = "Object") && !self { ; if everything failed, enumerate Object props
					for k, v in val.OwnProps()
						iter .= SubStr(_Print(k), 2, -1) ":" _Print(v?) ", "
				}
				iter := SubStr(iter, 1, StrLen(iter)-2)
				if !self && !iter && !((valType = "Array" && val.Length = 0) || (valType = "Map" && val.Count = 0) || (valType = "Object" && ObjOwnPropCount(val) = 0))
					return valType ; if no additional info is available, only print out the type
				else if self && iter
					out .= "value:" self ", iter:[" iter "]"
				else
					out .= self iter
				return (valType = "Object") ? "{" out "}" : (valType = "Array") ? "[" out "]" : valType "(" out ")"
		}
	}
}

/**
 * Returns all RegExMatch results in an array: [RegExMatchInfo1, RegExMatchInfo2, ...]
 * @param Haystack The string whose content is searched.
 * @param NeedleRegEx The RegEx pattern to search for.
 * @param StartingPosition If StartingPos is omitted, it defaults to 1 (the beginning of Haystack).
 * @returns {Array}
 */
RegExMatchAll(Haystack, NeedleRegEx, StartingPosition := 1) {
	out := []
	While StartingPosition := RegExMatch(Haystack, NeedleRegEx, &OutputVar, StartingPosition) {
		out.Push(OutputVar), StartingPosition += OutputVar[0] ? StrLen(OutputVar[0]) : 1
	}
	return out
}