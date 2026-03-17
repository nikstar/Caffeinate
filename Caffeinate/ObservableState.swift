//
//  State.swift
//  Caffeinate
//
//  Created by Nikita Starshinov on 18/11/2017.
//  Copyright © 2017 Nikita Starshinov. All rights reserved.
//

import Foundation

final class ObservableState {
    final class Observation {
        private var cancellation: (() -> Void)?

        init(cancellation: @escaping () -> Void) {
            self.cancellation = cancellation
        }

        func cancel() {
            cancellation?()
            cancellation = nil
        }

        deinit {
            cancel()
        }
    }

    private(set) var state: State
    private var observers: [UUID: (State) -> Void] = [:]

    init(state: State = State()) {
        self.state = state
    }

    var current: State {
        state
    }

    @discardableResult
    func observe(_ observer: @escaping (State) -> Void) -> Observation {
        let id = UUID()
        observers[id] = observer
        observer(state)

        return Observation { [weak self] in
            self?.observers.removeValue(forKey: id)
        }
    }

    @discardableResult
    func observeDistinct<Value: Equatable>(
        _ transform: @escaping (State) -> Value,
        onChange: @escaping (Value) -> Void
    ) -> Observation {
        var hasPreviousValue = false
        var previousValue: Value?

        return observe { state in
            let value = transform(state)

            if hasPreviousValue, previousValue! == value {
                return
            }

            previousValue = value
            hasPreviousValue = true
            onChange(value)
        }
    }

    func update<A>(_ keyPath: WritableKeyPath<State, A>, _ newValue: A) {
        var nextState = state
        nextState[keyPath: keyPath] = newValue

        guard nextState != state else {
            return
        }

        state = nextState
        notifyObservers()
    }

    private func notifyObservers() {
        let currentState = state
        let currentObservers = Array(observers.values)

        for observer in currentObservers {
            observer(currentState)
        }
    }
}

extension ObservableState {
    private static var url: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".caffeinate.json")
    }

    static func loadFromDisk() -> ObservableState {
        if let data = try? Data(contentsOf: url),
           let state = try? JSONDecoder().decode(State.self, from: data) {
            return ObservableState(state: state)
        }

        return ObservableState(state: State())
    }

    func saveToDisk() {
        do {
            let data = try JSONEncoder().encode(state)
            try data.write(to: ObservableState.url, options: .atomic)
        } catch {
            print("ObservableState: failed to save state: \(error)")
        }
    }
}
