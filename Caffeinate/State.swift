//
//  State.swift
//  Caffeinate
//
//  Created by Nikita Starshinov on 18/11/2017.
//  Copyright © 2017 Nikita Starshinov. All rights reserved.
//

import Foundation
import RxSwift

struct Settings: Codable {
    var keepScreenOn: Bool = false
    var timeout: Int? = nil
}

class State: Codable {
    var isActive = Variable(true)
    
    private var settingsValue = Settings() {
        didSet {
            settingsInput.onNext(settingsValue)
        }
    }
    private lazy var settingsInput = BehaviorSubject(value: self.settingsValue)
    lazy var settings = self.settingsInput.asObservable()
    
    init() { }
    
    func updateKeepScreenOn(_ newValue: Bool) {
        settingsValue.keepScreenOn = newValue
    }
    
    func updateTimeout(_ newValue: Int?) {
        settingsValue.timeout = newValue
    }
    
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
        case settings
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isActive.value = try container.decode(Bool.self, forKey: .isActive)
        settingsValue = try container.decode(Settings.self, forKey: .settings)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isActive.value, forKey: .isActive)
        try container.encode(settingsValue, forKey: .settings)
    }
}
