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
    var state: State
    
    lazy var isTimeRemainingVisible = Observable
        .combineLatest(self.state.isActive.asObservable(), self.state.timeout.asObservable()) { isActive, timeout in isActive && timeout != nil }
        .distinctUntilChanged()

    
    init(state: State) {
        self.state = state
    }
}
