import Foundation

enum ApiPaths {
    static let encrypt = "/api/v1/encrypt"
    static let encryptUint8 = "/api/v1/encrypt/uint8"
    static let encryptUint16 = "/api/v1/encrypt/uint16"
    static let encryptUint32 = "/api/v1/encrypt/uint32"
    static let encryptUint64 = "/api/v1/encrypt/uint64"
    static let encryptUint128 = "/api/v1/encrypt/uint128"
    static let encryptUint256 = "/api/v1/encrypt/uint256"
    static let encryptAddress = "/api/v1/encrypt/address"
    static let encryptBool = "/api/v1/encrypt/bool"
    static let encryptBatch = "/api/v1/encrypt/batch"
    static let health = "/health"
    static let healthReady = "/health/ready"
}
