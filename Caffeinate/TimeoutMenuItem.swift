//
//  TimeoutMenuItem.swift
//  Caffeinate
//
//  Created by Nikita Starshinov on 26/11/2018.
//  Copyright © 2018 Nikita Starshinov. All rights reserved.
//

import Cocoa
import RxSwift

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


