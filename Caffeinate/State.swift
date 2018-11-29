//
//  State.swift
//  Caffeinate
//
//  Created by Nikita Starshinov on 29/11/2018.
//  Copyright © 2018 Nikita Starshinov. All rights reserved.
//

import Foundation

struct Settings: Equatable, Codable {
    var keepScreenOn: Bool = false
    var timeout: Int? = nil
}

struct State: Equatable, Codable {
    var isActive: Bool = false
    var settings: Settings = Settings()
}
