//
//  Remaining.swift
//  Caffeinate
//
//  Created by Nikita Starshinov on 18/11/2017.
//  Copyright © 2017 Nikita Starshinov. All rights reserved.
//

import Foundation
import Cocoa

final class RemainingMenuItem: NSMenuItem {
    let viewModel: RemainingViewModel

    init(state: ObservableState) {
        viewModel = RemainingViewModel(state: state)

        super.init(title: "Remaining", action: nil, keyEquivalent: "")

        viewModel.onTimeRemainingChanged = { [weak self] timeRemaining in
            self?.title = formatter.string(from: timeRemaining) ?? "Time remaining"
        }
    }

    required init(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate let formatter: DateComponentsFormatter = {
    let f = DateComponentsFormatter()
    f.allowedUnits = [.hour, .minute]
    f.allowsFractionalUnits = false
    f.collapsesLargestUnit = true
    f.formattingContext = .listItem
    f.includesTimeRemainingPhrase = true
    f.maximumUnitCount = 1
    f.unitsStyle = DateComponentsFormatter.UnitsStyle.abbreviated
    return f
}()
