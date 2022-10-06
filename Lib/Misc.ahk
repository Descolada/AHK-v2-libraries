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
 * Prints the formatted value of a variable (number, string, array, map, object)
 * @param value Optional: the variable to print. 
 *     If omitted then new settings (output function and newline) will be set.
 * @param func Optional: the print function to use. Default is OutputDebug.
 *     Not providing a function will cause the output to simply be returned.
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
		if HasMethod(p)
			p(val)
		else
			return val
	}

	_Print(val?) {
		if !IsSet(val)
			return "unset"
		out := ""
		switch Type(val), 0 {
			case "String":
				return "'" val "'"
			case "Integer", "Float":
				return val
			case "Array":
				for k, v in val
					out .= _Print(v?) ", "
				return "[" SubStr(out, 1, StrLen(out)-2) "]"
			case "Map":
				for k, v in val
					out .= _Print(k) ":" _Print(v?) ", "
				return "Map(" SubStr(out, 1, StrLen(out)-2) ")"
			case "Object":
				for k, v in val.OwnProps()
					out .= k ":" _Print(v?) ", "
				return "{" SubStr(out, 1, StrLen(out)-2) "}"
			default:
				return Type(val)
		}
	}
}