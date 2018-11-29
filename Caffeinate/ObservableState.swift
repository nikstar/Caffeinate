//
//  State.swift
//  Caffeinate
//
//  Created by Nikita Starshinov on 18/11/2017.
//  Copyright © 2017 Nikita Starshinov. All rights reserved.
//

import Foundation
import RxSwift

class ObservableState {
    fileprivate var _state: State = State() {
        didSet {
            stateInput.onNext(_state)
        }
    }
    private lazy var stateInput = BehaviorSubject(value: self._state)
    lazy var state = self.stateInput.asObservable()
    
    init(state: State) {
        self._state = state
    }
    
    func update<A>(_ keyPath: WritableKeyPath<State, A>, _ newValue: A) {
        _state[keyPath: keyPath] = newValue
    }
}


extension ObservableState {
    private static var url: URL {
        return URL(fileURLWithPath: (NSHomeDirectory() as NSString).appendingPathComponent(".caffeinate.json"))
    }
    
    static func loadFromDisk() -> ObservableState {
        if let data = try? Data(contentsOf: url),
            let state = try? JSONDecoder().decode(State.self, from: data) {
            return ObservableState(state: state)
        }
        return ObservableState(state: State())                 
    }
    
    func saveToDisk() {
        let data = try! JSONEncoder().encode(_state)
        try! data.write(to: ObservableState.url)
    }
}
