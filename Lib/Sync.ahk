class Mutex {
    /**
     * Creates a new Mutex, or opens an existing one. The mutex is destroyed once all handles to
     * it are closed.
     * @param name Optional. The name can start with "Local\" to be session-local, or "Global\" to be 
     * available system-wide.
     * @param initialOwner Optional. If this value is TRUE and the caller created the mutex, the 
     * calling thread obtains initial ownership of the mutex object.
     * @param securityAttributes Optional. A pointer to a SECURITY_ATTRIBUTES structure.
     */
    __New(name?, initialOwner := 0, securityAttributes := 0) {
        if !(this.ptr := DllCall("CreateMutex", "ptr", securityAttributes, "int", !!initialOwner, "ptr", IsSet(name) ? StrPtr(name) : 0))
            throw Error("Unable to create or open the mutex", -1)
    }
    /**
     * Tries to lock (or signal) the mutex within the timeout period.
     * @param timeout The timeout period in milliseconds (default is infinite wait)
     * @returns {Integer} 0 = successful, 0x80 = abandoned, 0x120 = timeout, 0xFFFFFFFF = failed
     */
    Lock(timeout:=0xFFFFFFFF) => DllCall("WaitForSingleObject", "ptr", this, "int", timeout, "int")
    ; Releases the mutex (resets it back to the unsignaled state)
    Release() => DllCall("ReleaseMutex", "ptr", this)
    __Delete() => DllCall("CloseHandle", "ptr", this)
}

class Semaphore {
    /**
     * Creates a new semaphore or opens an existing one. The semaphore is destroyed once all handles
     * to it are closed.
     * 
     * CreateSemaphore argument list:
     * @param initialCount The initial count for the semaphore object. This value must be greater 
     * than or equal to zero and less than or equal to maximumCount.
     * @param maximumCount The maximum count for the semaphore object. This value must be greater than zero.
     * @param name Optional. The name of the semaphore object.
     * @param securityAttributes Optional. A pointer to a SECURITY_ATTRIBUTES structure.
     * @returns {Object}
     * 
     * OpenSemaphore argument list:
     * @param name The name of the semaphore object.
     * @param desiredAccess Optional: The desired access right to the semaphore object. Default is
     * SEMAPHORE_MODIFY_STATE = 0x0002
     * @param inheritHandle Optional: If this value is 1, processes created by this process will inherit the handle.
     * @returns {Object}
     */
    __New(initialCount, maximumCount?, name?, securityAttributes := 0) {
        if IsSet(initialCount) && IsSet(maximumCount) && IsInteger(initialCount) && IsInteger(maximumCount) {
            if !(this.ptr := DllCall("CreateSemaphore", "ptr", securityAttributes, "int", initialCount, "int", maximumCount, "ptr", IsSet(name) ? StrPtr(name) : 0))
                throw Error("Unable to create the semaphore", -1)
        } else if IsSet(initialCount) && initialCount is String {
            if !(this.ptr := DllCall("OpenSemaphore", "int", maximumCount ?? 0x0002, "int", !!(name ?? 0), "ptr", IsSet(initialCount) ? StrPtr(initialCount) : 0))
                throw Error("Unable to open the semaphore", -1)
        } else
            throw ValueError("Invalid parameter list!", -1)
    }
    /**
     * Tries to decrease the semaphore count by 1 within the timeout period.
     * @param timeout The timeout period in milliseconds (default is infinite wait)
     * @returns {Integer} 0 = successful, 0x80 = abandoned, 0x120 = timeout, 0xFFFFFFFF = failed
     */
    Wait(timeout:=0xFFFFFFFF) => DllCall("WaitForSingleObject", "ptr", this, "int", timeout, "int")
    /**
     * Increases the count of the specified semaphore object by a specified amount.
     * @param count Optional. How much to increase the count, default is 1.
     * @param out Is set to the result of the DllCall
     * @returns {number} The previous semaphore count
     */
    Release(count := 1, &out?) => (out := DllCall("ReleaseSemaphore", "ptr", this, "int", count, "int*", &prevCount:=0), prevCount)
    __Delete() => DllCall("CloseHandle", "ptr", this)
}

/* Waits for an object to be signaled within the timeout period.
 * @param timeout The timeout period in milliseconds (default is infinite wait)
 * @returns {Integer}
 * 0          = successful
 * 0x80       = abandoned
 * 0x120      = timeout
 * 0xFFFFFFFF = failed (A_LastError contains the error message)
 * @docs https://learn.microsoft.com/en-us/windows/win32/api/synchapi/nf-synchapi-waitforsingleobject
 */
WaitForSingleObject(obj, timeout:=0xFFFFFFFF) => DllCall("WaitForSingleObject", "ptr", obj, "int", timeout, "int")

/*
 * Waits for multiple objects to be signaled.
 * @param objArray An array of object handles, or AHK objects with ptr properties
 * @param waitAll If 1 then waits for all objects to be signaled, if 0 then at least one.
 * @param timeout The timeout period in milliseconds (default is infinite wait)
 * @returns {Integer}
 * 0          = successful
 * 0x80       = abandoned
 * 0x120      = timeout
 * 0xFFFFFFFF = failed (A_LastError contains the error message)
 * @docs https://learn.microsoft.com/en-us/windows/win32/api/synchapi/nf-synchapi-waitformultipleobjects
 */
WaitForMultipleObjects(objArray, waitAll:=1, timeout:=0xFFFFFFFF) {
    buf := Buffer(objArray.Length*A_PtrSize, 0)
    for i, obj in objArray
        NumPut("ptr", IsObject(obj) ? (obj.HasKey("ptr") ? obj.ptr : ObjPtr(obj)) : obj, buf, (i-1)*A_PtrSize)
    return DllCall("WaitForMultipleObjects", "int", objArray.Length, "ptr", buf, "int", !!waitAll, "int", timeout, "int")
}