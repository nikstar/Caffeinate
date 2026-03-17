//
//  Menu.swift
//  Caffeinate
//
//  Created by Nikita Starshinov on 19/01/2018.
//  Copyright © 2018 Nikita Starshinov. All rights reserved.
//

import Cocoa

final class Menu: NSResponder, NSMenuDelegate {
    let viewModel: MenuViewModel
    private var observations: [ObservableState.Observation] = []

    var statusBarItem: NSStatusItem = {
        let icon = Resources.menuIcon
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = icon
        item.button?.imagePosition = .imageOnly
        item.menu = NSMenu()
        return item
    }()

    var timeRemainingMenuItem: RemainingMenuItem
    var activateMenuItem: NSMenuItem! = nil
    var timeoutSubmenu: TimeoutSubmenu
    var keepScreenOnMenuItem: NSMenuItem! = nil
    var launchAtLoginMenuItem: NSMenuItem! = nil

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

    private func setupStructure() {
         self.activateMenuItem = MenuItem(title: "Activate", keyEquivalent: "a") { [viewModel] item in
            let currentState = item.title == "Deactivate"
            viewModel.updateActivate(!currentState)
        }
        self.keepScreenOnMenuItem = MenuItem(title: "Keep screen on", keyEquivalent: nil) { [viewModel] item in
            let currentState = item.state == .on
            viewModel.updateKeepScreenOn(!currentState)
        }
        self.launchAtLoginMenuItem = MenuItem(title: "Launch at Login", keyEquivalent: nil) { [viewModel] _ in
            viewModel.toggleLaunchAtLogin()
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
        statusBarItem.menu?.items = [
            self.timeRemainingMenuItem,
            self.activateMenuItem,
            .separator(),

            self.timeoutSubmenu,
            keepScreenOnMenuItem,
            launchAtLoginMenuItem,
            .separator(),

            sleepDisplayMenuItem,
            sleepMenuItem,
            .separator(),

            quitMenuItem
        ]
        statusBarItem.menu?.delegate = self
    }

    private func setupInteractions() {
        observations.append(viewModel.observeIsTimeRemainingVisible { [weak self] isVisible in
            self?.timeRemainingMenuItem.isHidden = !isVisible
        })

        observations.append(viewModel.observeIsActive { [weak self] isActive in
            guard let self else {
                return
            }

            self.activateMenuItem.title = isActive ? "Deactivate" : "Activate"
            self.statusBarItem.button?.appearsDisabled = !isActive
            self.statusBarItem.button?.alphaValue = 1.0
        })

        observations.append(viewModel.observeIsKeepScreenOnChecked { [weak self] newValue in
            self?.keepScreenOnMenuItem.state = newValue ? .on : .off
        })

        observations.append(viewModel.observeLaunchAtLoginStatus { [weak self] status in
            self?.launchAtLoginMenuItem.state = status.menuState
            self?.launchAtLoginMenuItem.title = status.title
        })
    }

    func menuWillOpen(_ menu: NSMenu) {
        viewModel.refreshLaunchAtLoginStatus()
    }
}

final class MenuItem: NSMenuItem {
    typealias Callback = (MenuItem) -> Void
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
