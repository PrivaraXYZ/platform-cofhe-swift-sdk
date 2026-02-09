import Foundation

struct InvalidParam: Codable, Sendable {
    let name: String
    let reason: String
}

struct ProblemDetail: Codable, Sendable {
    let type: String
    let title: String
    let status: Int
    let detail: String
    var instance: String = ""
    var invalidParams: [InvalidParam]?

    enum CodingKeys: String, CodingKey {
        case type, title, status, detail, instance, invalidParams
    }

    init(type: String, title: String, status: Int, detail: String, instance: String = "", invalidParams: [InvalidParam]? = nil) {
        self.type = type
        self.title = title
        self.status = status
        self.detail = detail
        self.instance = instance
        self.invalidParams = invalidParams
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        title = try container.decode(String.self, forKey: .title)
        status = try container.decode(Int.self, forKey: .status)
        detail = try container.decode(String.self, forKey: .detail)
        instance = try container.decodeIfPresent(String.self, forKey: .instance) ?? ""
        invalidParams = try container.decodeIfPresent([InvalidParam].self, forKey: .invalidParams)
    }
}
