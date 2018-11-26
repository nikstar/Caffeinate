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


class RemainingMenuItem: NSMenuItem {
    
    private(set) var startDate = Date()
    private(set) var timeout: TimeInterval = 0
    var endDate: Date {
        return startDate + timeout
    }
    
    private var disposeBag = DisposeBag()
    
    init(state: State) {
        super.init(title: "Remaining", action: nil, keyEquivalent: "")
        
        Observable
            .combineLatest(state.isActive.asObservable(), state.timeout.asObservable()) { _, timeout in
                self.startDate = Date()
                guard let timeout = timeout else { return }
                self.timeout = TimeInterval(timeout)
                
                self.refreshLabel()
            }
            .subscribe()
            .disposed(by: disposeBag)
        
        Observable<Int>
            .interval(20, scheduler: MainScheduler.instance)
            .subscribe(onNext: { _ in
                self.refreshLabel()
            })
            .disposed(by: disposeBag)
    }
    
    required init(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func refreshLabel() {
        DispatchQueue.main.async {
            self.title = formatter.string(from: Date(), to: self.endDate)!
        }
    }
}

