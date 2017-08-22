//
//  DependencyManager.swift
//  DemoApplication
//
//  Created by Saidi Daniel (BookBeat) on 2017-08-23.
//  Copyright © 2017 Daniel Saidi. All rights reserved.
//

import Dip
import Alamofire

class DependencyManager: NSObject {
    
    static func registerDependencies() {
        let dip = DependencyContainer()
        registerApi(dip)
        let container = DipContainer(container: dip)
        IoC.register(container)
        setupApi()
    }
    
    
    fileprivate static func registerApi(_ dip: DependencyContainer) {
        dip.register(.singleton) {
            NonPersistentApiContext(environment: .production) as ApiContext
        }
        
        dip.register {
            AlamofireAuthService(context: $0) as AuthService
        }
        
        dip.register {
            RealmMovieService(baseService: AlamofireMovieService(context: $0)) as MovieService
        }
    }
    
    fileprivate static func setupApi() {
        let manager = SessionManager.default
        manager.adapter = ApiRequestAdapter(context: IoC.resolve())
        manager.retrier = ApiRequestRetrier(context: IoC.resolve(), authService: IoC.resolve())
    }
}
