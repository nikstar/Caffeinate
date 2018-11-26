import Foundation

func sleepDisplay() {
    let cmd = Process()
    cmd.launchPath = "/usr/bin/pmset"
    cmd.arguments = ["displaysleepnow"]
    cmd.launch()
    cmd.waitUntilExit()
}
