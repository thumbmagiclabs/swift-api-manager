//
//  ProgressDelegate.swift
//  
//
//  Created by  on 24/01/2023.
//

import Foundation

public protocol ProgressDelegate: AnyObject {

    func didUpdateProgress(_ progress: Progress, for request: APIRequest)

}
