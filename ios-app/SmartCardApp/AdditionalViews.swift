import SwiftUI
import PassKit

// MARK: - Add Card View
struct AddCardView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var cardManager: CardManager
    
    @State private var nickname = ""
    @State private var cardType = "Chase"
    @State private var lastFour = ""
    @State private var isLoading = false
    
    private let cardTypes = ["Chase", "Amex", "Visa", "Mastercard"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Card Information") {
                    TextField("Card Nickname", text: $nickname)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Picker("Card Type", selection: $cardType) {
                        ForEach(cardTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    TextField("Last 4 Digits", text: $lastFour)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .onChange(of: lastFour) { newValue in
                            if newValue.count > 4 {
                                lastFour = String(newValue.prefix(4))
                            }
                        }
                }
                
                Section {
                    Button(action: addCard) {
                        if isLoading {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                Text("Adding Card...")
                            }
                        } else {
                            Text("Add Card")
                        }
                    }
                    .disabled(nickname.isEmpty || lastFour.isEmpty || isLoading)
                }
            }
            .navigationTitle("Add Real Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func addCard() {
        guard !nickname.isEmpty && !lastFour.isEmpty else { return }
        
        isLoading = true
        
        Task {
            let success = await cardManager.addRealCard(
                nickname: nickname,
                cardType: cardType,
                lastFour: lastFour
            )
            
            await MainActor.run {
                isLoading = false
                if success {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Wallet Provisioning View
struct WalletProvisioningView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var apiManager = APIManager()
    @State private var isWalletSupported = PKAddPaymentPassViewController.canAddPaymentPass()
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if isWalletSupported {
                    VStack(spacing: 16) {
                        Image(systemName: "wallet.pass")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Add to Apple Wallet")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Your Smart Card will be added to Apple Wallet and can be used for contactless payments.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Add to Apple Wallet") {
                            startWalletProvisioning()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                        
                        Text("Apple Wallet Not Supported")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("This device doesn't support Apple Wallet. You can still use your Smart Card for online purchases.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Apple Wallet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func startWalletProvisioning() {
        // For MVP, use a mock card ID
        let mockCardId = "card_1234567890"
        
        let config = PKAddPaymentPassRequestConfiguration(encryptionScheme: .ECC_V2)
        config.cardholderName = "Smart Card User"
        config.primaryAccountSuffix = "1234"
        config.localizedDescription = "Smart Wrapper Card"
        config.paymentNetwork = .visa
        
        let controller = PKAddPaymentPassViewController(requestConfiguration: config, delegate: WalletDelegate(cardId: mockCardId, apiManager: apiManager))
        
        if let controller = controller {
            // Present the wallet controller
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController?.present(controller, animated: true)
            }
        } else {
            errorMessage = "Failed to create wallet controller"
            showingError = true
        }
    }
}

// MARK: - Wallet Delegate
class WalletDelegate: NSObject, PKAddPaymentPassViewControllerDelegate {
    private let cardId: String
    private let apiManager: APIManager
    
    init(cardId: String, apiManager: APIManager) {
        self.cardId = cardId
        self.apiManager = apiManager
        super.init()
    }
    
    func addPaymentPassViewController(_ controller: PKAddPaymentPassViewController,
                                       generateRequestWithCertificateChain certificates: [Data],
                                       nonce: Data,
                                       nonceSignature: Data,
                                       completionHandler handler: @escaping (PKAddPaymentPassRequest) -> Void) {
        
        print("📱 Generating wallet pass request for card: \(cardId)")
        
        Task {
            let response = await apiManager.createWalletPass(
                nonce: nonce,
                nonceSignature: nonceSignature,
                certificates: certificates,
                cardId: cardId
            )
            
            await MainActor.run {
                if let response = response,
                   let activationData = Data(base64Encoded: response.activationData),
                   let encryptedPassData = Data(base64Encoded: response.encryptedPassData),
                   let ephemeralPublicKey = Data(base64Encoded: response.ephemeralPublicKey) {
                    
                    let passRequest = PKAddPaymentPassRequest()
                    passRequest.activationData = activationData
                    passRequest.encryptedPassData = encryptedPassData
                    passRequest.ephemeralPublicKey = ephemeralPublicKey
                    
                    handler(passRequest)
                } else {
                    // Handle error
                    print("❌ Failed to create wallet pass")
                    handler(PKAddPaymentPassRequest())
                }
            }
        }
    }
    
    func addPaymentPassViewControllerDidFinish(_ controller: PKAddPaymentPassViewController) {
        print("✅ Wallet provisioning completed")
        controller.dismiss(animated: true, completion: nil)
    }
}

// MARK: - Loading View
struct LoadingView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Error View
struct ErrorView: View {
    let message: String
    let retryAction: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Something went wrong")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if let retryAction = retryAction {
                Button("Try Again") {
                    retryAction()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}

#Preview {
    AddCardView()
        .environmentObject(CardManager())
}