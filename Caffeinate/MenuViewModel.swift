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
    fileprivate var state: State
    init(state: State) {
        self.state = state
    }

    lazy var isTimeRemainingVisible = Observable
        .combineLatest(self.state.isActive.asObservable(), self.state.timeout.asObservable()) { isActive, timeout in isActive && timeout != nil }
        .distinctUntilChanged()

    lazy var isActive = state.isActive.asObservable()
    lazy var keepScreenOn = state.keepScreenOn.asObservable()
    
    func toggleActivate() {
        state.isActive.value.toggle()
    }
    
    func toggleKeepScreenOn() {
        state.keepScreenOn.value.toggle()
    }
    
    func sleepDisplayAction() {
        sleepDisplay()
    }
    
    func quit() {
        NSApplication.shared.terminate(nil)
    }

}
