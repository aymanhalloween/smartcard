import Foundation

// MARK: - User Model
struct User: Identifiable, Codable {
    let id: String
    let email: String
    let name: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case createdAt = "created_at"
    }
}

// MARK: - Real Card Model
struct RealCard: Identifiable, Codable {
    let id: String
    let userId: String
    let nickname: String
    let cardType: String
    let lastFour: String
    let token: String
    let isActive: Bool
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case nickname
        case cardType = "card_type"
        case lastFour = "last_four"
        case token
        case isActive = "is_active"
        case createdAt = "created_at"
    }
}

// MARK: - Virtual Card Model
struct VirtualCard: Identifiable, Codable {
    let id: String
    let userId: String
    let stripeCardId: String
    let lastFour: String
    let status: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case stripeCardId = "stripe_card_id"
        case lastFour = "last_four"
        case status
        case createdAt = "created_at"
    }
}

// MARK: - Transaction Route Model
struct TransactionRoute: Identifiable, Codable {
    let id: String
    let transactionId: String
    let amount: Int
    let currency: String
    let mcc: String
    let merchantName: String
    let routedToCard: String
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case transactionId = "transaction_id"
        case amount
        case currency
        case mcc
        case merchantName = "merchant_name"
        case routedToCard = "routed_to_card"
        case timestamp
    }
}

// MARK: - API Response Models
struct CreateVirtualCardResponse: Codable {
    let success: Bool
    let card: VirtualCardData
}

struct VirtualCardData: Codable {
    let id: String
    let last4: String
    let status: String
}

struct AddRealCardResponse: Codable {
    let success: Bool
    let card: RealCardData
}

struct RealCardData: Codable {
    let id: String
    let nickname: String
    let cardType: String
    let lastFour: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case nickname
        case cardType = "cardType"
        case lastFour = "lastFour"
    }
}

struct UserCardsResponse: Codable {
    let realCards: [RealCard]
    let virtualCards: [VirtualCard]
    
    enum CodingKeys: String, CodingKey {
        case realCards = "realCards"
        case virtualCards = "virtualCards"
    }
}

struct TransactionsResponse: Codable {
    let transactions: [TransactionRoute]
}

// MARK: - Apple Wallet Models
struct WalletPassRequest: Codable {
    let nonce: String
    let nonceSignature: String
    let certificates: [String]
    let cardId: String
    
    enum CodingKeys: String, CodingKey {
        case nonce
        case nonceSignature = "nonceSignature"
        case certificates
        case cardId = "cardId"
    }
}

struct WalletPassResponse: Codable {
    let activationData: String
    let encryptedPassData: String
    let ephemeralPublicKey: String
    
    enum CodingKeys: String, CodingKey {
        case activationData = "activationData"
        case encryptedPassData = "encryptedPassData"
        case ephemeralPublicKey = "ephemeralPublicKey"
    }
}