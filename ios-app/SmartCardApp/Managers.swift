import Foundation
import Combine

// MARK: - Authentication Manager
class AuthManager: ObservableObject {
    @Published var isLoggedIn = false
    @Published var currentUser: User?
    
    private let baseURL = "http://localhost:3001/api"
    
    init() {
        // Check for existing session
        checkAuthStatus()
    }
    
    func login(email: String, password: String) {
        // Mock login for MVP - in production, call Supabase auth
        let user = User(
            id: "user_123",
            email: email,
            name: "Demo User",
            createdAt: Date()
        )
        
        DispatchQueue.main.async {
            self.currentUser = user
            self.isLoggedIn = true
        }
    }
    
    func demoLogin() {
        let user = User(
            id: "demo_user",
            email: "demo@smartcard.com",
            name: "Demo User",
            createdAt: Date()
        )
        
        DispatchQueue.main.async {
            self.currentUser = user
            self.isLoggedIn = true
        }
    }
    
    func signOut() {
        DispatchQueue.main.async {
            self.currentUser = nil
            self.isLoggedIn = false
        }
    }
    
    private func checkAuthStatus() {
        // Check for stored auth token
        // For MVP, just check if we have a demo user
        if let _ = UserDefaults.standard.string(forKey: "demo_user_id") {
            demoLogin()
        }
    }
}

// MARK: - Card Manager
class CardManager: ObservableObject {
    @Published var realCards: [RealCard] = []
    @Published var virtualCards: [VirtualCard] = []
    @Published var isLoading = false
    
    private let baseURL = "http://localhost:3001/api"
    
    func loadCards() {
        guard let userId = getCurrentUserId() else { return }
        
        isLoading = true
        
        // For MVP, load mock data
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.realCards = [
                RealCard(
                    id: "card_1",
                    userId: userId,
                    nickname: "Chase Sapphire",
                    cardType: "Chase",
                    lastFour: "1234",
                    token: "tok_chase_1234_1234567890",
                    isActive: true,
                    createdAt: Date()
                ),
                RealCard(
                    id: "card_2",
                    userId: userId,
                    nickname: "Amex Platinum",
                    cardType: "Amex",
                    lastFour: "5678",
                    token: "tok_amex_5678_1234567890",
                    isActive: true,
                    createdAt: Date()
                ),
                RealCard(
                    id: "card_3",
                    userId: userId,
                    nickname: "Amex Gold",
                    cardType: "Amex",
                    lastFour: "9012",
                    token: "tok_amex_9012_1234567890",
                    isActive: true,
                    createdAt: Date()
                )
            ]
            
            self.virtualCards = [
                VirtualCard(
                    id: "virtual_1",
                    userId: userId,
                    stripeCardId: "card_1234567890",
                    lastFour: "1234",
                    status: "active",
                    createdAt: Date()
                )
            ]
            
            self.isLoading = false
        }
    }
    
    func addRealCard(nickname: String, cardType: String, lastFour: String) async -> Bool {
        guard let userId = getCurrentUserId() else { return false }
        
        let request = [
            "userId": userId,
            "cardNickname": nickname,
            "cardType": cardType,
            "lastFour": lastFour
        ]
        
        do {
            let url = URL(string: "\(baseURL)/add-real-card")!
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: request)
            
            let (data, _) = try await URLSession.shared.data(for: urlRequest)
            let response = try JSONDecoder().decode(AddRealCardResponse.self, from: data)
            
            if response.success {
                // Add to local array
                let newCard = RealCard(
                    id: response.card.id,
                    userId: userId,
                    nickname: response.card.nickname,
                    cardType: response.card.cardType,
                    lastFour: response.card.lastFour,
                    token: "tok_\(cardType.lowercased())_\(lastFour)_\(Date().timeIntervalSince1970)",
                    isActive: true,
                    createdAt: Date()
                )
                
                DispatchQueue.main.async {
                    self.realCards.append(newCard)
                }
                
                return true
            }
        } catch {
            print("Error adding real card: \(error)")
        }
        
        return false
    }
    
    func createVirtualCard() async -> VirtualCard? {
        guard let userId = getCurrentUserId() else { return nil }
        
        let request = [
            "userId": userId,
            "cardholderName": "Smart Card User"
        ]
        
        do {
            let url = URL(string: "\(baseURL)/create-virtual-card")!
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: request)
            
            let (data, _) = try await URLSession.shared.data(for: urlRequest)
            let response = try JSONDecoder().decode(CreateVirtualCardResponse.self, from: data)
            
            if response.success {
                let newCard = VirtualCard(
                    id: UUID().uuidString,
                    userId: userId,
                    stripeCardId: response.card.id,
                    lastFour: response.card.last4,
                    status: response.card.status,
                    createdAt: Date()
                )
                
                DispatchQueue.main.async {
                    self.virtualCards.append(newCard)
                }
                
                return newCard
            }
        } catch {
            print("Error creating virtual card: \(error)")
        }
        
        return nil
    }
    
    private func getCurrentUserId() -> String? {
        // In a real app, get from AuthManager
        return "demo_user"
    }
}

// MARK: - API Manager
class APIManager: ObservableObject {
    private let baseURL = "http://localhost:3001/api"
    
    func createWalletPass(nonce: Data, nonceSignature: Data, certificates: [Data], cardId: String) async -> WalletPassResponse? {
        let request = WalletPassRequest(
            nonce: nonce.base64EncodedString(),
            nonceSignature: nonceSignature.base64EncodedString(),
            certificates: certificates.map { $0.base64EncodedString() },
            cardId: cardId
        )
        
        do {
            let url = URL(string: "\(baseURL)/create-wallet-pass")!
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = try JSONEncoder().encode(request)
            
            let (data, _) = try await URLSession.shared.data(for: urlRequest)
            let response = try JSONDecoder().decode(WalletPassResponse.self, from: data)
            
            return response
        } catch {
            print("Error creating wallet pass: \(error)")
            return nil
        }
    }
    
    func getTransactions(userId: String) async -> [TransactionRoute] {
        do {
            let url = URL(string: "\(baseURL)/transactions/\(userId)")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(TransactionsResponse.self, from: data)
            
            return response.transactions
        } catch {
            print("Error fetching transactions: \(error)")
            return []
        }
    }
}