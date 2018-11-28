//
//  TimeoutSubmenu.swift
//  Caffeinate
//
//  Created by Nikita Starshinov on 26/11/2018.
//  Copyright © 2018 Nikita Starshinov. All rights reserved.
//

import Cocoa
import RxSwift

class TimeoutSubmenu: NSMenuItem {
    let viewModel: TimeoutViewModel
    private var disposeBag = DisposeBag()
    
    init(state: ObservableState) {
        self.viewModel = TimeoutViewModel(state: state)
        
        super.init(title: "Timeout", action: nil, keyEquivalent: "")
        self.submenu = NSMenu()

        for timeout in allTimeoutOptions {
            let item = TimeoutMenuItem(timeout: timeout)
            item.target = self
            item.action = #selector(setTimeout(sender:))
            
            viewModel.selectedTimeout
                .subscribe(onNext: { selectedTimeout in
                    let isSelected = item.timeout == selectedTimeout
                    item.state = isSelected ? .on : .off
                })
                .disposed(by: disposeBag)
            
            self.submenu!.addItem(item)
        }
    }
    
    required init(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func setTimeout(sender: TimeoutMenuItem) {
        viewModel.setTimeout(sender.timeout)
    }
}
