//
//  AppDelegate.swift
//  Caffeinate
//
//  Created by Nikita Starshinov on 15/11/2017.
//  Copyright © 2017 Nikita Starshinov. All rights reserved.
//

import Cocoa

@main
final class AppDelegate: NSObject, NSApplicationDelegate {

    var state = ObservableState.loadFromDisk()
    var caffeinate: Caffeinate!
    var menu: Menu! {
        didSet {
            NSApplication.shared.nextResponder = menu as NSResponder
        }
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        self.caffeinate = Caffeinate(state: state)
        self.menu = Menu(state: state)
    }

    func applicationWillTerminate(_ notification: Notification) {
        caffeinate.forceStop()
        state.saveToDisk()
    }
}
