//
//  Caffeinate.swift
//  Caffeinate
//
//  Created by Nikita Starshinov on 16/11/2017.
//  Copyright © 2017 Nikita Starshinov. All rights reserved.
//

import Foundation
import RxSwift

final class Caffeinate {
    private var viewModel: CaffeinateViewModel
    
    private var process: Process? = nil

    private var disposeBag = DisposeBag()
    private var observer: NSObjectProtocol? = nil
    
    init(state: ObservableState) {
        self.viewModel = CaffeinateViewModel(state: state)
        setupObservers()
    }
    
    func setupObservers() {
        Observable
            .combineLatest(viewModel.isActive, viewModel.settings)
            .subscribe(onNext: {
                [unowned self] (isActive, settings) in
                print("Caffeinate: recieved new state: \((isActive, settings.keepScreenOn, settings.timeout))")
                if isActive {
                    self.start(settings: settings)
                } else {
                    self.forceStop()
                }
            })
            .disposed(by: disposeBag)
    }
    
    deinit {
        forceStop()
    }
    
    private func start(settings: Settings) {
        forceStop()
        process = {
            let p = Process()
            p.launchPath = "/usr/bin/caffeinate"
            p.arguments = []
            if settings.keepScreenOn {
                p.arguments?.append("-d")
            }
            if let timeout = settings.timeout {
                p.arguments?.append(contentsOf: ["-t", "\(timeout)"])
            }
            p.launch()
            
            return p
        }()
        watchForTermination()
    }
    
    func forceStop() {
        stopWatchingForTermination()
        guard let p = process else { return }
        defer {
            process = nil
        }
        guard p.isRunning else {
            print("Caffeinate: process has already finished with status: \(p.terminationStatus)")
            return
        }
        p.terminate()
        p.waitUntilExit()
        print("Caffeinate: process terminated with status: \(p.terminationStatus)")
    }
    
    private func watchForTermination() {
        guard let process = self.process else { fatalError() }
        observer = NotificationCenter.default.addObserver(forName: Process.didTerminateNotification, object: process, queue: nil) { [unowned self] note in
            print("Caffeinate: recieved notifiaction: \(note.name.rawValue)")
            self.viewModel.processDidTerminate()
            self.stopWatchingForTermination()
        }
    }
    
    private func stopWatchingForTermination() {
        if let o = self.observer {
            NotificationCenter.default.removeObserver(o)
            self.observer = nil
        }
    }
}

class CaffeinateViewModel {
    private var state: ObservableState
    
    init(state: ObservableState) {
        self.state = state
    }
    
    lazy var isActive = state.isActive.asObservable()
    var settings: Observable<Settings> { return state.settings }
    
    func processDidTerminate() {
        state.updateState(\State.isActive, false)
    }
}
