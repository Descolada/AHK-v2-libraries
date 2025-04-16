/*
	Name: Map.ahk
	Version 0.1 (05.09.23)
	Created: 05.09.23
	Author: Descolada

	Description:
	A compilation of useful Map methods.

    Map.Keys                              => All keys of the map in an array
    Map.Values                            => All values of the map in an array
    Map.Map(func, enums*)                 => Applies a function to each element in the map.
    Map.ForEach(func)                     => Calls a function for each element in the map.
    Map.Filter(func)                      => Keeps only key-value pairs that satisfy the provided function
    Map.Reduce(func, initialValue?)       => Applies a function cumulatively to all the values in 
        the array, with an optional initial value.
    Map.Find(func, &match?, start:=1)     => Finds a value satisfying the provided function and returns the index.
        match will be set to the found value. 
    Map.Count(value)                      => Counts the number of occurrences of a value.
    Map.Merge(enums*)                     => Adds the contents of other maps/enumerables to this map
*/

class Map2 {
    static __New() => (Map2.base := Map.Prototype.base, Map.Prototype.base := Map2)
    /**
     * Returns all the keys of the Map in an array
     * @returns {Array}
     */
    static Keys {
        get => [this*]
    }
    /**
     * Returns all the values of the Map in an array
     * @returns {Array}
     */
    static Values {
        get => [this.__Enum(2).Bind(&_)*]
    }

    /**
     * Applies a function to each element in the map (mutates the map).
     * @param func The mapping function that accepts at least key and value (key, value1, [value2, ...]).
     * @param enums Additional enumerables to be accepted in the mapping function
     * @returns {Map}
     */
    static Map(func, enums*) {
        if !HasMethod(func)
            throw ValueError("Map: func must be a function", -1)
        for k, v in this {
            bf := func.Bind(k,v)
            for _, vv in enums
                bf := bf.Bind(vv.Has(k) ? vv[k] : unset)
            try bf := bf()
            this[k] := bf
        }
        return this
    }
    /**
     * Applies a function to each key/value pair in the map.
     * @param func The callback function with arguments Callback(value[, key, map]).
     * @returns {Map}
     */
    static ForEach(func) {
        if !HasMethod(func)
            throw ValueError("ForEach: func must be a function", -1)
        for i, v in this
            func(v, i, this)
        return this
    }
    /**
     * Keeps only values that satisfy the provided function
     * @param func The filter function that accepts key and value.
     * @returns {Map}
     */
    static Filter(func) {
        if !HasMethod(func)
            throw ValueError("Filter: func must be a function", -1)
        r := Map()
        for k, v in this
            if func(k, v)
                r[k] := v
        return this := r
    }
    /**
     * Finds a value satisfying the provided function and returns its key.
     * @param func The condition function that accepts one argument (value).
     * @param match Optional: is set to the found value
     * @example
     * Map("a", 1, "b", 2, "c", 3).Find((v) => (Mod(v,2) == 0)) ; returns "b"
     */
    static Find(func, &match?) {
        if !HasMethod(func)
            throw ValueError("Find: func must be a function", -1)
        for k, v in this {
            if func(v) {
                match := v
                return k
            }
        }
        return 0
    }
    /**
     * Counts the number of occurrences of a value
     * @param value The value to count. Can also be a function that accepts a value and evaluates to true/false.
     */
    static Count(value) {
        count := 0
        if HasMethod(value) {
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
     * Adds the contents of other enumerables to this one.
     * @param enums The enumerables that are used to extend this one.
     * @returns {Array}
     */
    static Merge(enums*) {
        for i, enum in enums {
            if !HasMethod(enum, "__Enum")
                throw ValueError("Extend: argument " i " is not an iterable")
            for k, v in enum
                this[k] := v
        }
        return this
    }
}