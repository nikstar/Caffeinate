//
//  Timeout.swift
//  Caffeinate
//
//  Created by Nikita Starshinov on 18/11/2017.
//  Copyright © 2017 Nikita Starshinov. All rights reserved.
//

import Foundation
import Cocoa

struct Timeout {
    
    var seconds: Int?
    
    static let options: [Timeout] = [nil, 3600, 2*3600, 4*3600].map(Timeout.init)
    
    init(seconds: Int?) {
        self.seconds = seconds
    }
    
    func menuItem() -> TimeoutMenuItem {
        return TimeoutMenuItem(timeout: seconds)
    }

}

fileprivate let formatter: DateComponentsFormatter = {
    let f = DateComponentsFormatter()
    f.allowedUnits = [.hour, .minute, .second]
    f.allowsFractionalUnits = false
    f.collapsesLargestUnit = false
    f.formattingContext = .listItem
    f.maximumUnitCount = 2
    f.unitsStyle = DateComponentsFormatter.UnitsStyle.full
    
    return f
}()


class TimeoutMenuItem: NSMenuItem {
    let timeout: Int?
    
    init(timeout: Int?) {
        self.timeout = timeout
        let title: String
        if let timeout = timeout {
            title = formatter.string(from: TimeInterval(timeout))!
        } else {
            title = "None"
        }
        super.init(title: title, action: nil, keyEquivalent: "")
    }
    
    required init(coder decoder: NSCoder) {
        fatalError("Not implemented")
    }
}

