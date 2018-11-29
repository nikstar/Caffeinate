//
//  RemainingViewModel.swift
//  Caffeinate
//
//  Created by Nikita Starshinov on 26/11/2018.
//  Copyright © 2018 Nikita Starshinov. All rights reserved.
//

import Cocoa
import RxSwift

fileprivate var tickerTimeInterval = 20.0

class RemainingViewModel {
    fileprivate var state: ObservableState
    private var disposeBag = DisposeBag()
    
    private var ticker = Observable<Int>.interval(tickerTimeInterval, scheduler: MainScheduler.instance)
    
    private var timeRemainingInput = BehaviorSubject<TimeInterval>(value: 0.0)
    lazy var timeRemaining = self.timeRemainingInput.asObservable()
    
    init(state: ObservableState) {
        self.state = state
        
        state.state
            .subscribe(onNext: { state in
                self.startDate = Date()
                guard let timeout = state.settings.timeout else { return }
                self.timeout = TimeInterval(timeout)
                
                self.refreshLabel()
            })
            .disposed(by: disposeBag)
        
        ticker
            .withLatestFrom(state.state)
            .filter { $0.isActive == true }
            .subscribe(onNext: { _ in
                self.refreshLabel()
            })
            .disposed(by: disposeBag)

    }
    
    func refreshLabel() {
        timeRemainingInput.onNext(self.endDate.timeIntervalSinceNow)
    }
    
    private(set) var startDate = Date()
    private(set) var timeout: TimeInterval = 0
    var endDate: Date {
        return startDate + timeout
    }
    
    
}
