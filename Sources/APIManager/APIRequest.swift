//
//  APIRequest.swift
//  
//
//  Created by  on 24/01/2023.
//

import Alamofire
import Foundation

public protocol APIRequest {

    var endpoint: URL? { get }
    var method: HTTPMethod { get }
    var parameters: Parameters? { get }
    var headers: HTTPHeaders? { get }
    var requiresAuthentication: Bool { get }
    var encoding: ParameterEncoding { get }

}

public extension APIRequest {

    var parameters: Parameters? {
        return nil
    }

    var headers: HTTPHeaders? {
        let header = HTTPHeader(name: "Accept", value: "application/json")
        return [header]
    }

    var requiresAuthentication: Bool {
        true
    }

    var encoding: ParameterEncoding {
        method == .get ? URLEncoding() : JSONEncoding()
    }

}
