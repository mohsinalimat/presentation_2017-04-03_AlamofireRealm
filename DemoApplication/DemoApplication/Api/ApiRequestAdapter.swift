//
//  ApiRequestAdapter.swift
//  DemoApplication
//
//  Created by Saidi Daniel (BookBeat) on 2017-08-23.
//  Copyright © 2017 Daniel Saidi. All rights reserved.
//

import Alamofire

class ApiRequestAdapter: RequestAdapter {
    
    public init(context: ApiContext) {
        self.context = context
    }
    
    
    fileprivate let context: ApiContext
    
    
    func adapt(_ request: URLRequest) throws -> URLRequest {
        guard let token = context.authToken else { return request }
        var request = request
        request.setValue(token, forHTTPHeaderField: "AUTH_TOKEN")
        return request
    }
}
