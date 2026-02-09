import Foundation
#if canImport(os)
import os
#endif

/// Internal URLSession wrapper for HTTP operations.
final class HTTPClient: @unchecked Sendable {

    private let session: URLSession
    private let ownsSession: Bool
    private let baseURL: String
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    #if canImport(os)
    private let logger: os.Logger?
    #endif

    init(baseURL: String, session: URLSession?, enableLogging: Bool, requestTimeout: TimeInterval, connectTimeout: TimeInterval) {
        self.baseURL = baseURL

        if let session {
            self.session = session
            self.ownsSession = false
        } else {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = requestTimeout
            config.timeoutIntervalForResource = requestTimeout
            config.waitsForConnectivity = true
            config.httpAdditionalHeaders = ["Content-Type": "application/json"]
            self.session = URLSession(configuration: config)
            self.ownsSession = true
        }

        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()

        #if canImport(os)
        self.logger = enableLogging ? os.Logger(subsystem: "xyz.privara.cofhe.sdk", category: "HTTP") : nil
        #endif
    }

    func post<Req: Encodable, Res: Decodable>(path: String, body: Req) async throws -> Res {
        let url = URL(string: "\(baseURL)\(path)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)

        #if canImport(os)
        logger?.debug("POST \(path)")
        #endif

        let (data, response) = try await performRequest(request)
        return try parseResponse(data: data, response: response)
    }

    func get<Res: Decodable>(path: String) async throws -> Res {
        let url = URL(string: "\(baseURL)\(path)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        #if canImport(os)
        logger?.debug("GET \(path)")
        #endif

        let (data, response) = try await performRequest(request)
        return try parseResponse(data: data, response: response)
    }

    func getStatusCode(path: String) async throws -> Int {
        let url = URL(string: "\(baseURL)\(path)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (_, response) = try await performRequest(request)
        guard let httpResponse = response as? HTTPURLResponse else {
            return 0
        }
        return httpResponse.statusCode
    }

    func close() {
        if ownsSession {
            session.invalidateAndCancel()
        }
    }

    // MARK: - Private

    private func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch {
            throw CoFheError.networkError(message: "Failed to connect: \(error.localizedDescription)", underlyingError: error)
        }
    }

    private func parseResponse<T: Decodable>(data: Data, response: URLResponse) throws -> T {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CoFheError.networkError(
                message: "Invalid response type",
                underlyingError: URLError(.badServerResponse)
            )
        }

        if (200..<300).contains(httpResponse.statusCode) {
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw CoFheError.serializationError(
                    message: "Failed to parse response: \(error.localizedDescription)",
                    underlyingError: error
                )
            }
        }

        let bodyText = String(data: data, encoding: .utf8) ?? ""

        let problem: ProblemDetail
        if let parsed = try? decoder.decode(ProblemDetail.self, from: data) {
            problem = parsed
        } else {
            problem = ProblemDetail(
                type: "urn:fhe:error:unknown",
                title: "HTTP \(httpResponse.statusCode)",
                status: httpResponse.statusCode,
                detail: bodyText.isEmpty ? "No response body" : bodyText
            )
        }

        throw CoFheError.fromProblemDetail(problem)
    }
}
