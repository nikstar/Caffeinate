//
//  RemainingViewModel.swift
//  Caffeinate
//
//  Created by Nikita Starshinov on 26/11/2018.
//  Copyright © 2018 Nikita Starshinov. All rights reserved.
//

import Cocoa
import RxSwift

class RemainingViewModel {
    fileprivate var state: State
    private var disposeBag = DisposeBag()
    
    private var ticker = Observable<Int>.interval(20, scheduler: MainScheduler.instance)
    
    private var timeRemainingInput = BehaviorSubject<TimeInterval>(value: 0.0)
    lazy var timeRemaining = self.timeRemainingInput.asObservable()
    
    init(state: State) {
        self.state = state
        
        Observable
            .combineLatest(state.isActive.asObservable(), state.timeout.asObservable()) { _, timeout in
                self.startDate = Date()
                guard let timeout = timeout else { return }
                self.timeout = TimeInterval(timeout)
                
                self.refreshLabel()
            }
            .subscribe()
            .disposed(by: disposeBag)
        
        ticker
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
