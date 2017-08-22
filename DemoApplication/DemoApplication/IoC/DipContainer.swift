//
//  DipIocContainer.swift
//  iExtra
//
//  Created by Daniel Saidi on 2016-03-10.
//  Copyright © 2016 Daniel Saidi. All rights reserved.
//

import Dip

class DipContainer: NSObject, IoCContainer {
    
    init(container: DependencyContainer) {
        self.container = container
    }
    
    
    private var container: DependencyContainer
    
    
    func resolve<T>() -> T {
        return try! container.resolve()
    }
    
    func resolve<T, A>(arguments arg1: A) -> T {
        return try! container.resolve(arguments: arg1)
    }
    
    func resolve<T, A, B>(arguments arg1: A, _ arg2: B) -> T {
        return try! container.resolve(arguments: arg1, arg2)
    }
}
