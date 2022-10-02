/*
	Name: Misc.ahk
	Version 0.1 (26.08.22)
	Created: 26.08.22
	Author: Descolada (https://www.autohotkey.com/boards/viewtopic.php?f=83&t=107759)
    Credit: Coco

    1) Range method

        Syntax:
        Range(stop)
        Range(start, stop [, step ])

        Parameters:
        The arguments must be plain integers. If the step argument is omitted, it defaults to 1. 
        If the start argument is omitted, it defaults to 1. The full form is a sequence of plain 
        integers [start, start + step, start + 2 * step, ...], generated lazily. If step is 
        positive, the last element is the largest start + i * step less than stop; if step is 
        negative, the last element is the smallest start + i * step greater than stop. step must 
        not be zero or else an error is thrown. (mostly copy-paste from Coco's post, I'm lazy too :) )
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
}