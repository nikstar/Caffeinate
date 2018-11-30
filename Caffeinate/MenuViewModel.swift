//
//  MenuViewModel.swift
//  Caffeinate
//
//  Created by Nikita Starshinov on 26/11/2018.
//  Copyright © 2018 Nikita Starshinov. All rights reserved.
//

import Cocoa
import RxSwift

class MenuViewModel {
    fileprivate var state: ObservableState
    init(state: ObservableState) {
        self.state = state
    }
    
    lazy var isTimeRemainingVisible = state.observable
        .map { state in
            return state.isActive && state.settings.timeout != nil
        }
        .distinctUntilChanged()

    lazy var isActive = state.observable.map { $0.isActive }.distinctUntilChanged()
    lazy var isKeepScreenOnChecked = state.observable.map { $0.settings.keepScreenOn }.distinctUntilChanged()

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
