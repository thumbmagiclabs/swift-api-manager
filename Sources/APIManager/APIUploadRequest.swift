//
//  UploadRequest.swift
//  
//
//  Created by  on 24/01/2023.
//

import Alamofire
import Foundation

public protocol APIUploadRequest: APIRequest {

    func addData(to multipartData: MultipartFormData)

}
