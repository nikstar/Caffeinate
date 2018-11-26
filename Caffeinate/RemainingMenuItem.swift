//
//  Remaining.swift
//  Caffeinate
//
//  Created by Nikita Starshinov on 18/11/2017.
//  Copyright © 2017 Nikita Starshinov. All rights reserved.
//

import Foundation
import Cocoa
import RxSwift


class RemainingMenuItem: NSMenuItem {
    let viewModel: RemainingViewModel
    private var disposeBag = DisposeBag()
    
    init(state: State) {
        viewModel = RemainingViewModel(state: state)
        
        super.init(title: "Remaining", action: nil, keyEquivalent: "")
        
        viewModel.timeRemaining.subscribe(onNext: { timeRemaining in
            self.title = "\(formatter.string(from: timeRemaining)!)"
//            self.title = "\(debugFormatter.string(from: timeRemaining)!)"
        }).disposed(by: disposeBag)
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

fileprivate let debugFormatter: DateComponentsFormatter = {
    let f = DateComponentsFormatter()
    f.allowedUnits = [.hour, .minute, .second]
    f.allowsFractionalUnits = false
    f.collapsesLargestUnit = true
    f.formattingContext = .listItem
    f.maximumUnitCount = 3
    f.unitsStyle = DateComponentsFormatter.UnitsStyle.positional
    return f
}()
