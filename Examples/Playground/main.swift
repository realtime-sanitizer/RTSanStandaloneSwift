import RealtimeSanitizer

RealtimeSanitizer.ensureInitialized()

@NonBlocking
func process() { print("") }

// process()

@NonBlocking
func userBlocking() {
    RealtimeSanitizer.notifyBlockingCall(functionName: "userBlocking")
}

userBlocking()
