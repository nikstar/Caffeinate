//
//  TimeoutViewModel.swift
//  Caffeinate
//
//  Created by Nikita Starshinov on 26/11/2018.
//  Copyright © 2018 Nikita Starshinov. All rights reserved.
//

import Foundation

final class TimeoutViewModel {
    private let state: ObservableState

    init(state: ObservableState) {
        self.state = state
    }

    @discardableResult
    func observeSelectedTimeout(_ onChange: @escaping (Timeout) -> Void) -> ObservableState.Observation {
        state.observeDistinct(\.settings.timeout, onChange: onChange)
    }

    func setTimeout(_ newValue: Timeout) {
        state.update(\.settings.timeout, newValue)
    }
}
