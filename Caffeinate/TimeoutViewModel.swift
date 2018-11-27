//
//  TimeoutViewModel.swift
//  Caffeinate
//
//  Created by Nikita Starshinov on 26/11/2018.
//  Copyright © 2018 Nikita Starshinov. All rights reserved.
//

import Foundation

class TimeoutViewModel {
    fileprivate var state: State
    init(state: State) {
        self.state = state
    }

    lazy var selectedTimeout = self.state.settings.map { $0.timeout }
    
    func setTimeout(_ newValue: Timeout) {
        state.updateTimeout(newValue)
    }
}
