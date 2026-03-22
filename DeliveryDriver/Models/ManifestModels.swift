import Foundation

// Codable structs matching the manifest schema defined in the PRD (section 11).

struct ManifestResponse: Codable {
    let deliveries: [ManifestDelivery]?

    // Support both a wrapped {"deliveries":[...]} and a bare array response.
    init(from decoder: Decoder) throws {
        let container = try? decoder.container(keyedBy: CodingKeys.self)
        deliveries = try container?.decodeIfPresent([ManifestDelivery].self, forKey: .deliveries)
    }

    enum CodingKeys: String, CodingKey { case deliveries }
}

struct ManifestDelivery: Codable {
    let deliveryId: String
    let recipientName: String
    let addressLine1: String
    let addressLine2: String?
    let city: String
    let postcode: String
    let boxCount: Int
    let totalWeightKg: Double
    let specialInstructions: String?
    let status: String

    enum CodingKeys: String, CodingKey {
        case deliveryId          = "delivery_id"
        case recipientName       = "recipient_name"
        case addressLine1        = "address_line_1"
        case addressLine2        = "address_line_2"
        case city
        case postcode
        case boxCount            = "box_count"
        case totalWeightKg       = "total_weight_kg"
        case specialInstructions = "special_instructions"
        case status
    }
}
