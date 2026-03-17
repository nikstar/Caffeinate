//
//  MenuViewModel.swift
//  Caffeinate
//
//  Created by Nikita Starshinov on 26/11/2018.
//  Copyright © 2018 Nikita Starshinov. All rights reserved.
//

import Cocoa

final class MenuViewModel {
    private let state: ObservableState

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

    func updateActivate(_ newValue: Bool) {
        state.update(\.isActive, newValue)
    }

    func updateKeepScreenOn(_ newValue: Bool) {
        state.update(\.settings.keepScreenOn, newValue)
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
