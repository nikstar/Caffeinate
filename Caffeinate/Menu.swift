//
//  Menu.swift
//  Caffeinate
//
//  Created by Nikita Starshinov on 19/01/2018.
//  Copyright © 2018 Nikita Starshinov. All rights reserved.
//

import Cocoa
import RxSwift
import RxCocoa

class Menu: NSResponder {
    var viewModel: MenuViewModel
    
    var item: NSStatusItem = {
        let bar = NSStatusBar.system
        let item = bar.statusItem(withLength: NSStatusItem.variableLength)
        item.title = "Caf"
        item.highlightMode = true
        let menu = NSMenu()
        item.menu = menu
        
        return item
    }()
    
    var timeRemaining: RemainingMenuItem
    var activate: NSMenuItem! = nil
    var timeoutSubmenu: TimeoutSubmenu
    var keepScreenOn: NSMenuItem! = nil
    
    private var disposeBag = DisposeBag()
    
    init(state: State) {
        self.viewModel = MenuViewModel(state: state)
        
        self.timeRemaining = RemainingMenuItem(state: state)
        self.timeoutSubmenu = TimeoutSubmenu(state: state)
        
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
        
        root.addItem(timeRemaining)
        
        activate = NSMenuItem(title: "Activate", action: #selector(self.toggleActivate), keyEquivalent: "a")
        root.addItem(activate)
        
        root.addItem(.separator())
        
        root.addItem(timeoutSubmenu)
        
        keepScreenOn = NSMenuItem(title: "Keep screen on", action: #selector(self.toggleKeepScreenOn), keyEquivalent: "")
        root.addItem(keepScreenOn)
        let sleepDisplayItem = NSMenuItem(title: "Turn display off now", action: #selector(self.sleepDisplayAction), keyEquivalent: "")
        root.addItem(sleepDisplayItem)
        
        root.addItem(.separator())
        
        root.addItem(withTitle: "Quit", action: #selector(quit), keyEquivalent: "q")
    }
    
    func setupInteractions() {
        
        viewModel.isTimeRemainingVisible
            .subscribe(onNext: { [weak self] isVisible in
                self?.timeRemaining.isHidden = !isVisible
            })
            .disposed(by: disposeBag)
        
        viewModel.isActive
            .subscribe(onNext: { [unowned self] newValue in
                self.activate.title = newValue ? "Deactivate" : "Activate"
                self.item.title = newValue ? "Caf" : "caf"
            })
            .disposed(by: disposeBag)
        
        viewModel.keepScreenOn
            .subscribe(onNext: { [unowned self] newValue in
                self.keepScreenOn.state = newValue ? .on : .off
            })
            .disposed(by: disposeBag)
    }
    
    
    // MARK: - Actions
    
    @objc func toggleActivate() {
        viewModel.toggleActivate()
    }
    
    @objc func toggleKeepScreenOn() {
        let currentState = keepScreenOn.state == .on
        viewModel.updateKeepScreenOn(!currentState)
    }
    
    @objc func sleepDisplayAction() {
        viewModel.sleepDisplayAction()
    }
    
    @objc func quit() {
        viewModel.quit()
    }
}
