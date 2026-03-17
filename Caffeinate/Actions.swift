import Foundation

func sleepDisplay() {
    runPmset(["displaysleepnow"])
}

func sleep() {
    runPmset(["sleepnow"])
}

private func runPmset(_ arguments: [String]) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
    process.arguments = arguments

    do {
        try process.run()
        process.waitUntilExit()
    } catch {
        print("Actions: failed to run pmset \(arguments): \(error)")
    }
}
