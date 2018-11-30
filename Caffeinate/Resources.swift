//
//  Resources.swift
//  Caffeinate
//
//  Created by Nikita Starshinov on 01/12/2018.
//  Copyright © 2018 Nikita Starshinov. All rights reserved.
//

import Cocoa

enum Resources {
    static let menuIcon: NSImage = {
        let i = Bundle.main.image(forResource: "coffee")!
        i.isTemplate = true
        i.size = NSSize(width: 16, height: 16)
        return i
    }()
}

