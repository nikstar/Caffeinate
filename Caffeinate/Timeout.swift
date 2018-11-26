//
//  Timeout.swift
//  Caffeinate
//
//  Created by Nikita Starshinov on 18/11/2017.
//  Copyright © 2017 Nikita Starshinov. All rights reserved.
//

import Foundation
import Cocoa

typealias Timeout = Int?

let allTimeoutOptions: [Timeout] = [nil, 3600, 2*3600, 4*3600]





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




