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
    private var disposeBag = DisposeBag()
    
    var statusBarItem: NSStatusItem = {
        let icon = Resources.menuIcon
        let item = NSStatusBar.system.statusItem(withLength: icon.size.width + 10) // a bit off center
        item.button!.image = icon
        item.menu = NSMenu()
        return item
    }()
    
    var timeRemainingMenuItem: RemainingMenuItem
    var activateMenuItem: NSMenuItem! = nil
    var timeoutSubmenu: TimeoutSubmenu
    var keepScreenOnMenuItem: NSMenuItem! = nil
    
    init(state: ObservableState) {
        self.viewModel = MenuViewModel(state: state)
        self.timeRemainingMenuItem = RemainingMenuItem(state: state)
        self.timeoutSubmenu = TimeoutSubmenu(state: state)
        
        super.init()
        
        setupStructure()
        setupInteractions()
    }
    
    required init(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupStructure() {
         self.activateMenuItem = MenuItem(title: "Activate", keyEquivalent: "a") { [viewModel] item in
            let currentState = item.title == "Deactivate"
            viewModel.updateActivate(!currentState)
        }
        self.keepScreenOnMenuItem = MenuItem(title: "Keep screen on", keyEquivalent: nil) { [viewModel] item in
            let currentState = item.state == .on
            viewModel.updateKeepScreenOn(!currentState)
        }
        let sleepDisplayMenuItem = MenuItem(title: "Turn off display", keyEquivalent: nil) { [viewModel] _ in
            viewModel.sleepDisplayAction()
        }
        let sleepMenuItem = MenuItem(title: "Sleep", keyEquivalent: nil) { [viewModel] _ in
            viewModel.sleepAction()
        }
        let quitMenuItem = MenuItem(title: "Quit Caffeinate", keyEquivalent: "q") { [viewModel] _ in
            viewModel.quit()
        }
        statusBarItem.menu!.items = [
            self.timeRemainingMenuItem,
            self.activateMenuItem,
            .separator(),
            
            self.timeoutSubmenu,
            keepScreenOnMenuItem,
            .separator(),
            
            sleepDisplayMenuItem,
            sleepMenuItem,
            .separator(),
            
            quitMenuItem
        ]
    }
    
    func setupInteractions() {
        viewModel.isTimeRemainingVisible
            .subscribe(onNext: { [weak self] isVisible in
                self?.timeRemainingMenuItem.isHidden = !isVisible
            })
            .disposed(by: disposeBag)
        
        viewModel.isActive
            .subscribe(onNext: { [unowned self] isActive in
                self.activateMenuItem.title = isActive ? "Deactivate" : "Activate"
                self.statusBarItem.button!.appearsDisabled = !isActive
            })
            .disposed(by: disposeBag)
        
        viewModel.isKeepScreenOnChecked
            .subscribe(onNext: { [unowned self] newValue in
                self.keepScreenOnMenuItem.state = newValue ? .on : .off
            })
            .disposed(by: disposeBag)
    }
 }


class MenuItem: NSMenuItem {
    typealias Callback = (MenuItem) -> ()
    var callback: Callback?
    
    init(title: String, keyEquivalent: String?, action callback: Callback?) {
        self.callback = callback
        super.init(title: title, action: nil, keyEquivalent: keyEquivalent ?? "")
        self.target = self
        self.action = #selector(onClick)
    }
    
    required init(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func onClick() {
        callback?(self)
    }
}
