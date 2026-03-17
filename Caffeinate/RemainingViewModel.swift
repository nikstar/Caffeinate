//
//  RemainingViewModel.swift
//  Caffeinate
//
//  Created by Nikita Starshinov on 26/11/2018.
//  Copyright © 2018 Nikita Starshinov. All rights reserved.
//

import Foundation

private let tickerTimeInterval: TimeInterval = 20.0

final class RemainingViewModel {
    private let state: ObservableState
    private var stateObservation: ObservableState.Observation?
    private var ticker: Timer?

    var onTimeRemainingChanged: ((TimeInterval) -> Void)? {
        didSet {
            refreshLabel()
        }
    }

    private(set) var startDate = Date()
    private(set) var timeout: TimeInterval = 0

    var endDate: Date {
        startDate.addingTimeInterval(timeout)
    }

    init(state: ObservableState) {
        self.state = state
        stateObservation = state.observe { [weak self] state in
            self?.handleStateChange(state)
        }
    }

    deinit {
        stopTicker()
    }

    func refreshLabel() {
        let timeRemaining = max(0, endDate.timeIntervalSinceNow)
        onTimeRemainingChanged?(timeRemaining)
    }

    private func handleStateChange(_ state: State) {
        startDate = Date()

        guard let timeout = state.settings.timeout else {
            self.timeout = 0
            stopTicker()
            onTimeRemainingChanged?(0)
            return
        }

        self.timeout = TimeInterval(timeout)
        refreshLabel()

        if state.isActive {
            startTicker()
        } else {
            stopTicker()
        }
    }

    private func startTicker() {
        guard ticker == nil else {
            return
        }

        let ticker = Timer(timeInterval: tickerTimeInterval, repeats: true) { [weak self] _ in
            self?.refreshLabel()
        }
        RunLoop.main.add(ticker, forMode: .common)
        self.ticker = ticker
    }

    private func stopTicker() {
        ticker?.invalidate()
        ticker = nil
    }
}
