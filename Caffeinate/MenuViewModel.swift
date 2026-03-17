//
//  MenuViewModel.swift
//  Caffeinate
//
//  Created by Nikita Starshinov on 26/11/2018.
//  Copyright © 2018 Nikita Starshinov. All rights reserved.
//

import Cocoa
import ServiceManagement

final class MenuViewModel {
    private let state: ObservableState
    private let launchAtLoginService = LaunchAtLoginService()

    init(state: ObservableState) {
        self.state = state
    }

    @discardableResult
    func observeIsTimeRemainingVisible(_ onChange: @escaping (Bool) -> Void) -> ObservableState.Observation {
        state.observeDistinct({ $0.isActive && $0.settings.timeout != nil }, onChange: onChange)
    }

    @discardableResult
    func observeIsActive(_ onChange: @escaping (Bool) -> Void) -> ObservableState.Observation {
        state.observeDistinct(\.isActive, onChange: onChange)
    }

    @discardableResult
    func observeIsKeepScreenOnChecked(_ onChange: @escaping (Bool) -> Void) -> ObservableState.Observation {
        state.observeDistinct(\.settings.keepScreenOn, onChange: onChange)
    }

    @discardableResult
    func observeLaunchAtLoginStatus(_ onChange: @escaping (LaunchAtLoginService.Status) -> Void) -> ObservableState.Observation {
        launchAtLoginService.observeStatus(onChange)
    }

    func updateActivate(_ newValue: Bool) {
        state.update(\.isActive, newValue)
    }

    func updateKeepScreenOn(_ newValue: Bool) {
        state.update(\.settings.keepScreenOn, newValue)
    }

    func toggleLaunchAtLogin() {
        launchAtLoginService.toggle()
    }

    func refreshLaunchAtLoginStatus() {
        launchAtLoginService.refreshStatus()
    }

    func sleepDisplayAction() {
        sleepDisplay()
    }

    func sleepAction() {
        sleep()
    }

    func quit() {
        NSApplication.shared.terminate(nil)
    }
}

final class LaunchAtLoginService {
    enum Status: Equatable {
        case unavailable
        case notRegistered
        case enabled
        case requiresApproval

        var menuState: NSControl.StateValue {
            switch self {
            case .enabled:
                return .on
            case .requiresApproval:
                return .mixed
            case .notRegistered, .unavailable:
                return .off
            }
        }

        var title: String {
            switch self {
            case .requiresApproval:
                return "Launch at Login (Needs Approval)"
            case .enabled, .notRegistered, .unavailable:
                return "Launch at Login"
            }
        }
    }

    private var observers: [UUID: (Status) -> Void] = [:]
    private(set) var status: Status = .unavailable

    init() {
        refreshStatus()
    }

    @discardableResult
    func observeStatus(_ observer: @escaping (Status) -> Void) -> ObservableState.Observation {
        let id = UUID()
        observers[id] = observer
        observer(status)

        return ObservableState.Observation { [weak self] in
            self?.observers.removeValue(forKey: id)
        }
    }

    func toggle() {
        switch status {
        case .enabled, .requiresApproval:
            setEnabled(false)
        case .notRegistered, .unavailable:
            setEnabled(true)
        }
    }

    func refreshStatus() {
        let newStatus = currentStatus()

        guard newStatus != status else {
            return
        }

        status = newStatus
        notifyObservers()
    }

    private func setEnabled(_ shouldEnable: Bool) {
        guard #available(macOS 13.0, *) else {
            status = .unavailable
            notifyObservers()
            presentAlert(
                title: "Launch at Login Unavailable",
                message: "This feature requires macOS 13 or newer."
            )
            return
        }

        do {
            if shouldEnable {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            refreshStatus()
            presentAlert(
                title: "Launch at Login Failed",
                message: error.localizedDescription
            )
            return
        }

        let previousStatus = status
        status = currentStatus()
        notifyObservers()

        if shouldEnable, previousStatus != .requiresApproval, status == .requiresApproval {
            presentAlert(
                title: "Approval Required",
                message: "Approve Caffeinate in System Settings > General > Login Items."
            )
        }
    }

    private func currentStatus() -> Status {
        guard #available(macOS 13.0, *) else {
            return .unavailable
        }

        switch SMAppService.mainApp.status {
        case .enabled:
            return .enabled
        case .requiresApproval:
            return .requiresApproval
        case .notRegistered, .notFound:
            return .notRegistered
        @unknown default:
            return .notRegistered
        }
    }

    private func notifyObservers() {
        let currentStatus = status
        let currentObservers = Array(observers.values)

        for observer in currentObservers {
            observer(currentStatus)
        }
    }

    private func presentAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.runModal()
    }
}
