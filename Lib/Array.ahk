/*
	Name: Array.ahk
	Version 0.4.1 (02.09.24)
	Created: 27.08.22
	Author: Descolada

	Description:
	A compilation of useful array methods.

    Array.Slice(start:=1, end:=0, step:=1)  => Returns a section of the array from 'start' to 'end', 
        optionally skipping elements with 'step'.
    Array.Swap(a, b)                        => Swaps elements at indexes a and b.
    Array.Map(func, arrays*)                => Applies a function to each element in the array and returns a new array.
    Array.ForEach(func)                     => Calls a function for each element in the array.
    Array.Filter(func)                      => Keeps only values that satisfy the provided function and returns a new array with the results.
    Array.Reduce(func, initialValue?)       => Applies a function cumulatively to all the values in 
        the array, with an optional initial value.
    Array.IndexOf(value, start:=1)          => Finds a value in the array and returns its index.
    Array.Find(func, &match?, start:=1)     => Finds a value satisfying the provided function and returns the index.
        match will be set to the found value. 
    Array.Reverse()                         => Reverses the array.
    Array.Count(value)                      => Counts the number of occurrences of a value.
    Array.Sort(OptionsOrCallback?, Key?)    => Sorts an array, optionally by object values.
    Array.Shuffle()                         => Randomizes the array.
    Array.Unique()                          => Returns a set of the values in the array
    Array.Join(delim:=",")                  => Joins all the elements to a string using the provided delimiter.
    Array.Flat()                            => Turns a nested array into a one-level array.
    Array.Extend(enums*)                    => Adds the values of other arrays or enumerables to the end of this one.
*/

class Array2 {
    static __New() => (Array2.base := Array.Prototype.base, Array.Prototype.base := Array2)
    /**
     * Returns a section of the array from 'start' to 'end', optionally skipping elements with 'step'.
     * Modifies the original array.
     * @param start Optional: index to start from. Default is 1.
     * @param end Optional: index to end at. Can be negative. Default is 0 (includes the last element).
     * @param step Optional: an integer specifying the incrementation. Default is 1.
     * @returns {Array}
     */
    static Slice(start:=1, end:=0, step:=1) {
        len := this.Length, i := start < 1 ? len + start + 1 : start, j := Min(end < 1 ? len + end + 1 : end, len), r := [], reverse := False
        if step = 0
            Throw ValueError("Slice: step cannot be 0", -1)
        if len = 0
            return []
        if i < 1
            i := 1
        r.Length := r.Capacity := Abs(j+1-i) // step
        if step < 0 {
            while i >= j {
                if this.Has(i)
                    r[A_Index] := this[i]
                i += step
            }
        } else {
            while i <= j {
                if this.Has(i)
                    r[A_Index] := this[i]
                i += step
            }
        }
        return r
    }
    /**
     * Swaps elements at indexes a and b
     * @param a First elements index to swap
     * @param b Second elements index to swap
     * @returns {Array}
     */
    static Swap(a, b) {
        temp := this.Has(b) ? this[b] : unset
        this.Has(a) ? (this[b] := this[a]) : this.Delete(b)
        IsSet(temp) ? (this[a] := temp) : this.Delete(a)
        return this
    }
    /**
     * Applies a function to each element in the array and returns a new array with the results.
     * @param func The mapping function that accepts one argument.
     * @param arrays Additional arrays to be accepted in the mapping function
     * @returns {Array}
     */
    static Map(func, arrays*) {
        if !HasMethod(func)
            throw ValueError("Map: func must be a function", -1)
        local new := this.Clone()
        for i, v in new {
            bf := func.Bind(v?)
            for _, vv in arrays
                bf := bf.Bind(vv.Has(i) ? vv[i] : unset)
            try bf := bf()
            new[i] := bf
        }
        return new
    }
    /**
     * Applies a function to each element in the array.
     * @param func The callback function with arguments Callback(value[, index, array]).
     * @returns {Array}
     */
    static ForEach(func) {
        if !HasMethod(func)
            throw ValueError("ForEach: func must be a function", -1)
        for i, v in this
            func(v?, i, this)
        return this
    }
    /**
     * Keeps only values that satisfy the provided function and returns a new array with the results.
     * @param func The filter function that accepts one argument.
     * @returns {Array}
     */
    static Filter(func) {
        if !HasMethod(func)
            throw ValueError("Filter: func must be a function", -1)
        r := []
        for v in this
            if func(v?)
                r.Push(v)
        return r
    }
    /**
     * Applies a function cumulatively to all the values in the array, with an optional initial value.
     * @param func The function that accepts two arguments and returns one value
     * @param initialValue Optional: the starting value. If omitted, the first value in the array is used.
     * @returns {func return type}
     * @example
     * [1,2,3,4,5].Reduce((a,b) => (a+b)) ; returns 15 (the sum of all the numbers)
     */
    static Reduce(func, initialValue?) {
        if !HasMethod(func)
            throw ValueError("Reduce: func must be a function", -1)
        len := this.Length + 1
        if len = 1
            return initialValue ?? ""
        if IsSet(initialValue)
            out := initialValue, i := 0
        else
            out := this[1], i := 1
        while ++i < len {
            out := func(out?, this.Has(i) ? this[i] : unset)
        }
        return out
    }
    /**
     * Finds a value in the array and returns its index.
     * @param value The value to search for.
     * @param start Optional: the index to start the search from, negative start reverses the search. Default is 1.
     */
    static IndexOf(value?, start:=1) {
        local len := this.Length, reverse := false
        if !IsInteger(start)
            throw ValueError("IndexOf: start value must be an integer", -1)
        if start < 0
            reverse := true, start := len+1+start
        if start < 1 || start > len
            return 0
        if reverse {
            ++start
            if IsSet(value) {
                while --start > 0
                    if this.Has(start) && (this[start] == value)
                        return start
            } else {
                while --start > 0
                    if !this.Has(start)
                        return start
            }
        } else {
            --start
            if IsSet(value) {
                while ++start <= len
                    if this.Has(start) && (this[start] == value)
                        return start
            } else {
                while ++start <= len
                    if !this.Has(start)
                        return start
            }
        }
        return 0
    }
    /**
     * Finds a value satisfying the provided function and returns its index.
     * @param func The condition function that accepts one argument.
     * @param match Optional: is set to the found value
     * @param start Optional: the index to start the search from, negative start reverses the search. Default is 1.
     * @example
     * [1,2,3,4,5].Find((v) => (Mod(v,2) == 0)) ; returns 2
     */
    static Find(func, &match?, start:=1) {
        local reverse := false
        if !HasMethod(func)
            throw ValueError("Find: func must be a function", -1)
        local len := this.Length
        if start < 0
            reverse := true, start := len+1+start
        if start < 1 || start > len
            return 0

        if reverse {
            ++start
            while --start > 0
                if ((v := (this.Has(start) ? this[start] : unset)), func(v?))
                    return ((match := v ?? unset), start)
        } else {
            --start
            while ++start <= len
                if ((v := (this.Has(start) ? this[start] : unset)), func(v?))
                    return ((match := v ?? unset), start)
        }
        return 0
    }
    /**
     * Reverses the array.
     * @example
     * [1,2,3].Reverse() ; returns [3,2,1]
     */
    static Reverse() {
        local len := this.Length + 1, max := (len // 2), i := 0
        while ++i <= max
            this.Swap(i, len - i)
        return this
    }
    /**
     * Counts the number of occurrences of a value
     * @param value The value to count. Can also be a function.
     */
    static Count(value?) {
        count := 0
        if !IsSet(value) {
            Loop this.Length
                if this.Has(A_Index)
                    count++
        } else if HasMethod(value) {
            for _, v in this
                if value(v?)
                    count++
        } else
            for _, v in this
                if v == value
                    count++
        return count
    }
    /**
     * Sorts an array, optionally by object keys
     * @param OptionsOrCallback Optional: either a callback function, or one of the following:
     * 
     *     N => array is considered to consist of only numeric values. This is the default option.
     *     C, C1 or COn => case-sensitive sort of strings
     *     C0 or COff => case-insensitive sort of strings
     * 
     *     The callback function should accept two parameters elem1 and elem2 and return an integer:
     *     Return integer < 0 if elem1 less than elem2
     *     Return 0 is elem1 is equal to elem2
     *     Return > 0 if elem1 greater than elem2
     * @param Key Optional: Omit it if you want to sort a array of primitive values (strings, numbers etc).
     *     If you have an array of objects, specify here the key by which contents the object will be sorted.
     * @returns {Array}
     */
    static Sort(optionsOrCallback:="N", key?) {
        if (this.Length < 2)
            return this
        if HasMethod(optionsOrCallback)
            compareFunc := optionsOrCallback, optionsOrCallback := ""
        else {
            if InStr(optionsOrCallback, "N")
                compareFunc := IsSet(key) ? NumericCompareKey.Bind(key) : NumericCompare
            if RegExMatch(optionsOrCallback, "i)C(?!0)|C1|COn")
                compareFunc := IsSet(key) ? StringCompareKey.Bind(key,,True) : StringCompare.Bind(,,True)
            if RegExMatch(optionsOrCallback, "i)C0|COff")
                compareFunc := IsSet(key) ? StringCompareKey.Bind(key) : StringCompare
            if InStr(optionsOrCallback, "Random")
                return this.Shuffle()
            if !IsSet(compareFunc)
                throw ValueError("No valid options provided!", -1)
        }
        QuickSort(1, this.Length)
        if RegExMatch(optionsOrCallback, "i)R(?!a)")
            this.Reverse()
        if InStr(optionsOrCallback, "U")
            this := this.Unique()
        return this

        NumericCompare(left, right) => (left > right) - (left < right)
        NumericCompareKey(key, left, right) => ((f1 := left.HasProp("__Item") ? left[key] : left.%key%), (f2 := right.HasProp("__Item") ? right[key] : right.%key%), (f1 > f2) - (f1 < f2))
        StringCompare(left, right, casesense := False) => StrCompare(left "", right "", casesense)
        StringCompareKey(key, left, right, casesense := False) => StrCompare((left.HasProp("__Item") ? left[key] : left.%key%) "", (right.HasProp("__Item") ? right[key] : right.%key%) "", casesense)

        ; In-place quicksort (Hoare-style partition with middle pivot)
        QuickSort(left, right) {
            i := left
            j := right
            pivot := this[(left + right) // 2]

            while (i <= j) {
                while (compareFunc(this[i], pivot) < 0)
                    i++
                while (compareFunc(this[j], pivot) > 0)
                    j--
                if (i <= j) {
                    temp := this[i], this[i] := this[j], this[j] := temp
                    i++, j--
                }
            }
            if (left < j)
                QuickSort(left, j)
            if (i < right)
                QuickSort(i, right)
        }
    }
    /**
     * Randomizes the array.
     * @returns {Array}
     */
    static Shuffle() {
        len := this.Length
        Loop len-1
            this.Swap(A_index, Random(A_index, len))
        return this
    }
    /**
     * Returns a set of values in array
     */
    static Unique() {
        unique := Map()
        for v in this
            unique[v] := 1
        return [unique*]
    }
    /**
     * Joins all the elements to a string using the provided delimiter.
     * @param delim Optional: the delimiter to use. Default is comma.
     * @returns {String}
     */
	static Join(delim:=",") {
		result := ""
		for v in this
			result .= (v ?? "") delim
		return (len := StrLen(delim)) ? SubStr(result, 1, -len) : result
	}
    /**
     * Turns a nested array into a one-level array
     * @returns {Array}
     * @example
     * [1,[2,[3]]].Flat() ; returns [1,2,3]
     */
    static Flat() {
        r := []
        for v in this {
            if !IsSet(v)
                r.Length += 1
            else if v is Array
                r.Push(v.Flat()*)
            else
                r.Push(v)
        }
        return this := r
    }
    /**
     * Adds the contents of another array to the end of this one.
     * @param enums The arrays or other enumerables that are used to extend this one.
     * @returns {Array}
     */
    static Extend(enums*) {
        for enum in enums {
            if !HasMethod(enum, "__Enum")
                throw ValueError("Extend: arr must be an iterable")
            for _, v in enum
                this.Push(v)
        }
        return this
    }
}