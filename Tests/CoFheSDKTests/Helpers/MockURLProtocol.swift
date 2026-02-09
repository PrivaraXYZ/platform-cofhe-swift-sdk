import Foundation

/// Custom URLProtocol for intercepting HTTP requests in tests.
///
/// Usage:
/// ```swift
/// MockURLProtocol.requestHandler = { request in
///     let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
///     return (response, jsonData)
/// }
/// let session = URLSession(configuration: MockURLProtocol.sessionConfiguration)
/// ```
final class MockURLProtocol: URLProtocol {

    /// Handler called for each intercepted request. Return `(HTTPURLResponse, Data?)`.
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data?))?

    /// A ready-made session configuration with this protocol registered.
    static var sessionConfiguration: URLSessionConfiguration {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return config
    }

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        // URLSession converts httpBody to httpBodyStream internally.
        // Read the stream so tests can access the body data.
        var enrichedRequest = request
        if enrichedRequest.httpBody == nil, let stream = request.httpBodyStream {
            stream.open()
            var data = Data()
            let bufferSize = 1024
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            defer { buffer.deallocate() }
            while stream.hasBytesAvailable {
                let read = stream.read(buffer, maxLength: bufferSize)
                if read > 0 {
                    data.append(buffer, count: read)
                }
            }
            stream.close()
            enrichedRequest.httpBody = data
        }

        do {
            let (response, data) = try handler(enrichedRequest)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            if let data {
                client?.urlProtocol(self, didLoad: data)
            }
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
