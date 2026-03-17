//
//  TimeoutSubmenu.swift
//  Caffeinate
//
//  Created by Nikita Starshinov on 26/11/2018.
//  Copyright © 2018 Nikita Starshinov. All rights reserved.
//

import Cocoa

final class TimeoutSubmenu: NSMenuItem {
    let viewModel: TimeoutViewModel
    private var timeoutItems: [TimeoutMenuItem] = []
    private var selectedTimeoutObservation: ObservableState.Observation?

    init(state: ObservableState) {
        self.viewModel = TimeoutViewModel(state: state)

        super.init(title: "Timeout", action: nil, keyEquivalent: "")
        self.submenu = NSMenu()

        for timeout in allTimeoutOptions {
            let item = TimeoutMenuItem(timeout: timeout)
            item.target = self
            item.action = #selector(setTimeout(sender:))
            timeoutItems.append(item)
            self.submenu?.addItem(item)
        }

        selectedTimeoutObservation = viewModel.observeSelectedTimeout { [weak self] selectedTimeout in
            self?.updateSelection(selectedTimeout)
        }
    }

    required init(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func setTimeout(sender: TimeoutMenuItem) {
        viewModel.setTimeout(sender.timeout)
    }

    private func updateSelection(_ selectedTimeout: Timeout) {
        for item in timeoutItems {
            item.state = item.timeout == selectedTimeout ? .on : .off
        }
    }
}
