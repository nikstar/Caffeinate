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
    
    unowned var state: State
    
    private var process: Process? = nil

    private var disposeBag = DisposeBag()
    private var observer: NSObjectProtocol? = nil
    
    init(state: State) {
        self.state = state
        
        Observable
            .combineLatest(state.isActive.asObservable(), state.keepScreenOn.asObservable(), state.timeout.asObservable()) {
                [unowned self] isActive, keepScreenOn, timeout in
                print("Caffeinate: recieved new state: \((isActive, keepScreenOn, timeout))")
                if isActive {
                    self.start(keepScreenOn: keepScreenOn, timeout: timeout)
                } else {
                    self.stop()
                }
            }
            .subscribe()
            .disposed(by: disposeBag)
    }
    
    deinit {
//        if let observer = observer {
//            NotificationCenter.default.removeObserver(observer)
//        }
    }
    
    
    private func start(keepScreenOn: Bool, timeout: Int?) {
        if process != nil { stop() }
        process = {
            let p = Process()
            p.launchPath = "/usr/bin/caffeinate"
            p.arguments = []
            if keepScreenOn {
                p.arguments?.append("-d")
            }
            if let timeout = timeout {
                p.arguments?.append(contentsOf: ["-t", "\(timeout)"])
            }
            p.launch()
            
            observer = NotificationCenter.default.addObserver(forName: Process.didTerminateNotification, object: p, queue: nil) { [unowned self] note in
                print("Caffeinate: recieved notifiaction: \(note.name.rawValue)")
                self.state.isActive.value = false
                if let o = self.observer {
                    NotificationCenter.default.removeObserver(o)
                    self.observer = nil
                }
            }
            return p
        }()
    }
    
    func stop() {
        if let o = self.observer { // find a better way to avoid this situatuion
            NotificationCenter.default.removeObserver(o)
            self.observer = nil
        }
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
}

