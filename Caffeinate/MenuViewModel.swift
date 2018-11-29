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
    
    lazy var isTimeRemainingVisible = Observable
        .combineLatest(self.state.isActive.asObservable(), self.state.settings) { isActive, settings in
            return isActive && settings.timeout != nil }
        .distinctUntilChanged()

    lazy var isActive = state.isActive
    lazy var keepScreenOn = state.settings.map { $0.keepScreenOn }
    lazy var timeout = state.settings.map { $0.timeout }

    func toggleActivate() {
        state.toggleActivate()
    }
    
    func updateKeepScreenOn(_ newValue: Bool) {
        state.update(\State.settings.keepScreenOn, newValue)
    }
    
    func sleepDisplayAction() {
        sleepDisplay()
    }
    
    func quit() {
        NSApplication.shared.terminate(nil)
    }

}
