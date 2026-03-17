//
//  Caffeinate.swift
//  Caffeinate
//
//  Created by Nikita Starshinov on 16/11/2017.
//  Copyright © 2017 Nikita Starshinov. All rights reserved.
//

import Foundation

final class Caffeinate {
    private let state: ObservableState
    private var process: Process? = nil
    private var stateObservation: ObservableState.Observation?
    private var observer: NSObjectProtocol? = nil

    init(state: ObservableState) {
        self.state = state
        stateObservation = state.observe { [weak self] state in
            guard let self else {
                return
            }

            print("Caffeinate: received new state: \((state.isActive, state.settings.keepScreenOn, state.settings.timeout))")
            if state.isActive {
                self.start(settings: state.settings)
            } else {
                self.forceStop()
            }
        }
    }

    deinit {
        forceStop()
    }

    private func start(settings: Settings) {
        forceStop()

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
        process.arguments = []

        if settings.keepScreenOn {
            process.arguments?.append("-d")
        }
        if let timeout = settings.timeout {
            process.arguments?.append(contentsOf: ["-t", "\(timeout)"])
        }

        do {
            try process.run()
        } catch {
            print("Caffeinate: failed to launch process: \(error)")
            state.update(\.isActive, false)
            return
        }

        self.process = process
        watchForTermination()
    }

    func forceStop() {
        stopWatchingForTermination()
        guard let p = process else { return }
        defer {
            process = nil
        }
        guard p.isRunning else {
            print("Caffeinate: process has already finished with status: \(p.terminationStatus)")
            return
        }
        p.terminate()
        p.waitUntilExit()
        print("Caffeinate: process terminated with status: \(p.terminationStatus)")
    }

    func processDidTerminate() {
        state.update(\State.isActive, false)
    }

    private func watchForTermination() {
        guard let process = self.process else {
            return
        }

        observer = NotificationCenter.default.addObserver(
            forName: Process.didTerminateNotification,
            object: process,
            queue: .main
        ) { [weak self] note in
            print("Caffeinate: received notification: \(note.name.rawValue)")
            self?.processDidTerminate()
            self?.stopWatchingForTermination()
        }
    }

    private func stopWatchingForTermination() {
        if let o = self.observer {
            NotificationCenter.default.removeObserver(o)
            self.observer = nil
        }
    }
}
