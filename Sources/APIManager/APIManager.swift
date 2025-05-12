import Alamofire
import Foundation

public class APIManager {

    public let authProvider: AuthProvider

    public init(authProvider: AuthProvider) {
        self.authProvider = authProvider
    }

    ///Performs requests in parallel and returns the the response when all requests are done
    /// - Parameters:
    ///    - request: `[APIRequest]` the requests to perform
    /// - Returns: The created `[Data]`
    public func performRequests(_ requests: [APIRequest]) async throws -> [Data] {

        try await withThrowingTaskGroup(of: (Int, Data).self) { group in

            for (index, request) in requests.enumerated() {
                group.addTask {
                    let data = try await self.performRequest(request)
                    return (index, data)
                }
            }

            var responseData: [Data?] = Array(repeating: nil, count: requests.count)

            for try await (index, data) in group {
                responseData[index] = data
            }

            return responseData.compactMap({ $0 })
        }
    }

    ///Performs a request asynchronously
    /// - Parameters:
    ///    - request: `APIRequest` the request to perform
    /// - Returns: The created `Data`
    public func performRequest(_ request: APIRequest) async throws -> Data {

        guard let url = request.endpoint else {
            throw APIError.notFound
        }

        var headers = request.headers ?? []

        if request.requiresAuthentication {
            let authHeader = await authProvider.authenticationHeader()
            headers.add(authHeader)
        }

        let request = AF.request(
            url, method: request.method,
            parameters: request.parameters,
            encoding: request.encoding,
            headers: headers
        )

        let response = await request.serializingData().response
        let data = try getData(from: response)

        return data
    }

    ///Downloads the response of the request into a local file
    /// - Parameters:
    ///    - request: `APIRequest` the request to perform
    /// - Returns: The created file `URL`
    public func downloadRequest(
        _ request: APIRequest,
        destinationURL: URL? = nil,
        progressDelegate: ProgressDelegate? = nil
    ) async throws -> URL {
        guard let url = request.endpoint else {
            throw APIError.notFound
        }

        let destination: DownloadRequest.Destination

        if let destinationURL {
            destination = { _, _ in
                return (destinationURL, [.removePreviousFile, .createIntermediateDirectories])
            }
        } else {
            destination = DownloadRequest.suggestedDownloadDestination(for: .documentDirectory)
        }


        var headers = request.headers ?? []

        if request.requiresAuthentication {
            let authHeader = await authProvider.authenticationHeader()
            headers.add(authHeader)
        }

        let request = AF.download(
            url, method: request.method,
            parameters: request.parameters,
            encoding: request.encoding,
            headers: headers,
            to: destination
        ).downloadProgress(closure: { progress in
            progressDelegate?.didUpdateProgress(progress, for: request)
        })

        let response = await request.serializingData().response
        let fileUrl = try getURL(from: response)

        return fileUrl
    }

    ///Uploads data using multipart
    /// - Parameters:
    ///    - request: `APIUploadRequest` the request to perform
    /// - Returns: The created `Data`
    public func uploadRequest(_ request: APIUploadRequest) async throws -> Data {

        guard let url = request.endpoint else {
            throw APIError.notFound
        }

        var headers = request.headers ?? []

        if request.requiresAuthentication {
            let authHeader = await authProvider.authenticationHeader()
            headers.add(authHeader)
        }


        let uploadRequest = AF.upload(
            multipartFormData: request.addData,
            to: url,
            method: request.method,
            headers: headers)

        let response = await uploadRequest.serializingData().response
        let data = try getData(from: response)

        return data
    }
}

extension APIManager {

    private func getData(from response: DataResponse<Data, AFError>) throws -> Data {

        if response.response?.statusCode == 401 {
            throw APIError.unauthorized
        }

        if let error = response.error {
            throw error
        }

        guard let data = response.data else {
            throw APIError.unableToDecodeData
        }

        return data
    }

    private func getURL(from response: DownloadResponse<Data, AFError>) throws -> URL {

        if response.response?.statusCode == 401 {
            throw APIError.unauthorized
        }

        if let error = response.error {
            throw error
        }

        guard let url = response.fileURL else {
            throw APIError.unableToDecodeData
        }

        return url
    }
}
