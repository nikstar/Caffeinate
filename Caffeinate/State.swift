//
//  State.swift
//  Caffeinate
//
//  Created by Nikita Starshinov on 18/11/2017.
//  Copyright © 2017 Nikita Starshinov. All rights reserved.
//

import Foundation
import RxSwift

class State: Codable {
    var isActive = Variable(true)
    var keepScreenOn = Variable(false)
    var timeout: Variable<Int?> = Variable(nil)

    init() { }
    
    
    // MARK: Persistence
    
    private static let url = URL(fileURLWithPath: (NSHomeDirectory() as NSString).appendingPathComponent(".caffeinate.json"))
    
    static func loadFromDisk() -> State {
        if let data = try? Data(contentsOf: url),
            let state = try? JSONDecoder().decode(State.self, from: data) {
            return state
        }
        return State()
    }
    
    func saveToDisk() {
        let data = try! JSONEncoder().encode(self)
        try! data.write(to: State.url)
    }
    
    enum CodingKeys: String, CodingKey {
        case isActive
        case keepScreenOn
        case timeout
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isActive.value = try container.decode(Bool.self, forKey: .isActive)
        keepScreenOn.value = try container.decode(Bool.self, forKey: .keepScreenOn)
        timeout.value = try container.decode(Optional<Int>.self, forKey: .timeout)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isActive.value, forKey: .isActive)
        try container.encode(keepScreenOn.value, forKey: .keepScreenOn)
        try container.encode(timeout.value, forKey: .timeout)
    }
}
