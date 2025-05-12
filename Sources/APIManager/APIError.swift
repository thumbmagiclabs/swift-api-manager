//
//  APIError.swift
//  
//
//  Created by  on 24/01/2023.
//

import Foundation

public enum APIError: String, Error {

    case notFound
    case unauthorized
    case serverError
    case unableToDecodeData
    case `unknown`

    public var localizedDescription: String {
        rawValue
    }

}

