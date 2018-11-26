//
//  Menu.swift
//  Caffeinate
//
//  Created by Nikita Starshinov on 19/01/2018.
//  Copyright © 2018 Nikita Starshinov. All rights reserved.
//

import Cocoa
import RxSwift

class Menu: NSResponder {
    unowned var state: State
    
    var item: NSStatusItem = {
        let bar = NSStatusBar.system
        let item = bar.statusItem(withLength: NSStatusItem.variableLength)
        item.title = "Caf"
        item.highlightMode = true
        let menu = NSMenu()
        item.menu = menu
        
        return item
    }()
    
    var timeRemaining: RemainingMenuItem! = nil
    var activate: NSMenuItem! = nil
    var timeoutSettings: [TimeoutMenuItem] = []
    var keepScreenOn: NSMenuItem! = nil
    
    private var disposeBag = DisposeBag()
    
    init(state: State) {
        self.state = state
        
        super.init()
        
        setupStructure()
        setupInteractions()
    }
    
    required init(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - Setup
    
    func setupStructure() {
        // .
        // |- (hidden) Time remaining
        // |- Activate
        // |- ---
        // |- Timeout
        //    |- ....
        // |- Keep screen on
        // |- Turn off display now
        // |- ---
        // |- Quit
        
        let root = item.menu!
        
        timeRemaining = RemainingMenuItem(state: state)
        root.addItem(timeRemaining)
        
        activate = NSMenuItem(title: "Activate", action: #selector(self.toggleActivate), keyEquivalent: "a")
        root.addItem(activate)
        
        root.addItem(.separator())
        
        let timeout = NSMenuItem()
        root.addItem(timeout)
        timeout.title = "Timeout"
        timeout.submenu = NSMenu()
        for item in Timeout.options.map({ $0.menuItem() }) {
            item.action = #selector(setTimeout(sender:))
            timeout.submenu!.addItem(item)
            timeoutSettings.append(item)
        }
        
        keepScreenOn = NSMenuItem(title: "Keep screen on", action: #selector(self.toggleKeepScreenOn), keyEquivalent: "")
        root.addItem(keepScreenOn)
        let sleepDisplayItem = NSMenuItem(title: "Turn display off now", action: #selector(self.sleepDisplayAction), keyEquivalent: "")
        root.addItem(sleepDisplayItem)
        
        root.addItem(.separator())
        
        root.addItem(withTitle: "Quit", action: #selector(quit), keyEquivalent: "q")
    }
    
    func setupInteractions() {
        // Time remaining
        Observable
            .combineLatest(state.isActive.asObservable(), state.timeout.asObservable()) { isActive, timeout in isActive && timeout != nil }
            .distinctUntilChanged()
            .subscribe(onNext: { [unowned self] visible in
                self.timeRemaining.isHidden = !visible
            })
            .disposed(by: disposeBag)
        
        // Activate
        state.isActive.asObservable()
            .subscribe(onNext: { [unowned self] newValue in
                self.activate.title = newValue ? "Deactivate" : "Activate"
                self.item.title = newValue ? "Caf" : "caf"
            })
            .disposed(by: disposeBag)
        
        // Timeouts
        state.timeout.asObservable()
            .subscribe(onNext: { [unowned self] newValue in
                for t in self.timeoutSettings {
                    t.state = t.timeout == newValue ? .on : .off
                }
            })
            .disposed(by: disposeBag)
        
        // Keep screen on
        state.keepScreenOn.asObservable()
            .subscribe(onNext: { [unowned self] newValue in
                self.keepScreenOn.state = newValue ? .on : .off
            })
            .disposed(by: disposeBag)
    }
    
    
    // MARK: - Actions
    
    @objc func toggleActivate() {
        state.isActive.value.toggle()
    }
    
    @objc func setTimeout(sender: TimeoutMenuItem) {
        state.timeout.value = sender.timeout
    }
    
    @objc func toggleKeepScreenOn() {
        state.keepScreenOn.value.toggle()
    }
    
    @objc func sleepDisplayAction() {
        sleepDisplay()
    }
    
    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
}
