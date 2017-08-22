//
//  ApiRequestRetrier.swift
//  DemoApplication
//
//  Created by Saidi Daniel (BookBeat) on 2017-08-22.
//  Copyright © 2017 Daniel Saidi. All rights reserved.
//

/*
 
 In the real world, a 401 status code is an indication
 that any tokens should be refreshed. However, in this
 fake API demo, we will fake a failing request using a
 404. This means NOT FOUND and should NOT be used when
 you build real apps. Never. Ever.
 
 */

import Alamofire

class ApiRequestRetrier: RequestRetrier {
    
    init(context: ApiContext, authService: AuthService) {
        self.context = context
        self.authService = authService
    }
    
    
    fileprivate let authService: AuthService
    fileprivate let context: ApiContext
    fileprivate var isAuthorizing = false
    fileprivate var retryQueue = [RequestRetryCompletion]()
    
    
    func should(
        _ manager: SessionManager,
        retry request: Request,
        with error: Error,
        completion: @escaping RequestRetryCompletion) {
        
        guard
            shouldRetryRequest(with: request.request?.url),
            shouldRetryResponse(with: request.response?.statusCode)
            else { return completion(false, 0) }
        
        authorize(with: completion)
    }
    
    
    fileprivate func authorize(with completion: @escaping RequestRetryCompletion) {
        print("Authorizing application...")
        retryQueue.append(completion)
        guard !isAuthorizing else { return }
        isAuthorizing = true
        authService.authorizeApplication { (token, error) in
            self.printAuthResult(token, error)
            self.isAuthorizing = false
            self.context.authToken = token
            let success = token != nil
            self.retryQueue.forEach { $0(success, 0) }
            self.retryQueue.removeAll()
        }
    }
    
    fileprivate func printAuthResult(_ token: String?, _ error: Error?) {
        if let error = error {
            return print("Authorizing failed: \(error.localizedDescription)")
        }
        if let token = token {
            return print("Authorizing succeded: \(token)")
        }
        print("No token received - failing!")
    }
    
    fileprivate func shouldRetryRequest(with url: URL?) -> Bool {
        guard let url = url?.absoluteString else { return false }
        let authPath = ApiRoute.auth.path
        return !url.contains(authPath)
    }
    
    fileprivate func shouldRetryResponse(with statusCode: Int?) -> Bool {
        return true // statusCode == 401
    }
}
