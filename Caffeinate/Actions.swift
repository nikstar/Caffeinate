import Foundation

func sleepDisplay() {
    let cmd = Process()
    cmd.launchPath = "/usr/bin/pmset"
    cmd.arguments = ["displaysleepnow"]
    cmd.launch()
    cmd.waitUntilExit()
}

func sleep() {
    let cmd = Process()
    cmd.launchPath = "/usr/bin/pmset"
    cmd.arguments = ["sleepnow"]
    cmd.launch()
    cmd.waitUntilExit()
}
