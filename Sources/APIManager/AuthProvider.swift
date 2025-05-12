//
//  AuthProvider.swift
//  
//
//  Created by  on 24/01/2023.
//

import Alamofire
import Foundation

public protocol AuthProvider {

    func authenticationHeader() async -> HTTPHeader

}
