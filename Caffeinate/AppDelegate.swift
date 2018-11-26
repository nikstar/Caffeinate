//
//  AppDelegate.swift
//  Caffeinate
//
//  Created by Nikita Starshinov on 15/11/2017.
//  Copyright © 2017 Nikita Starshinov. All rights reserved.
//

import Cocoa
import RxSwift
import RxCocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var state = State.loadFromDisk()
    var caffeinate: Caffeinate! = nil
    var menu: Menu! = nil
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        caffeinate = Caffeinate(state: state)
        menu = Menu(state: state)
        NSApplication.shared.nextResponder = menu as NSResponder
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        caffeinate.stop()
        state.saveToDisk()
    }
}


