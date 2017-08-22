//
//  AlamofireService.swift
//  DemoApplication
//
//  Created by Daniel Saidi on 2017-08-22.
//  Copyright © 2017 Daniel Saidi. All rights reserved.
//

import Alamofire

class AlamofireService {    
    
    init(context: ApiContext) {
        self.context = context
    }
    
    
    var context: ApiContext
    
    
    func get(at route: ApiRoute, params: Parameters? = nil) -> DataRequest {
        return request(at: route, method: .get, params: params, encoding: URLEncoding.default)
    }
    
    func post(at route: ApiRoute, params: Parameters? = nil) -> DataRequest {
        return request(at: route, method: .post, params: params, encoding: JSONEncoding.default)
    }
    
    func put(at route: ApiRoute, params: Parameters? = nil) -> DataRequest {
        return request(at: route, method: .put, params: params, encoding: JSONEncoding.default)
    }
    
    func request(at route: ApiRoute, method: HTTPMethod, params: Parameters?, encoding: ParameterEncoding) -> DataRequest {
        let url = route.url(for: context.environment)
        return Alamofire.request(url, method: method, parameters: params, encoding: encoding).validate()
    }
}
