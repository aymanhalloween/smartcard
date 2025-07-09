import SwiftUI
import PassKit

struct ContentView: View {
    @StateObject private var authManager = AuthManager()
    @StateObject private var cardManager = CardManager()
    
    var body: some View {
        if authManager.isLoggedIn {
            MainAppView()
                .environmentObject(authManager)
                .environmentObject(cardManager)
        } else {
            LoginView()
                .environmentObject(authManager)
        }
    }
}

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Smart Card")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Your intelligent credit card wrapper")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 60)
                
                // Login Form
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: login) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Sign In")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(isLoading)
                }
                .padding(.horizontal, 32)
                
                // Demo login button
                Button("Demo Login (Skip Auth)") {
                    authManager.demoLogin()
                }
                .foregroundColor(.blue)
                .padding(.top, 20)
                
                Spacer()
            }
            .padding()
        }
    }
    
    private func login() {
        isLoading = true
        // Mock login - in real app, call Supabase auth
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            authManager.login(email: email, password: password)
            isLoading = false
        }
    }
}

struct MainAppView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var cardManager: CardManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            CardsView()
                .tabItem {
                    Image(systemName: "creditcard")
                    Text("Cards")
                }
                .tag(0)
            
            TransactionsView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Transactions")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(2)
        }
        .onAppear {
            cardManager.loadCards()
        }
    }
}

struct CardsView: View {
    @EnvironmentObject var cardManager: CardManager
    @State private var showingAddCard = false
    @State private var showingWalletProvisioning = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Smart Card Section
                VStack(spacing: 16) {
                    HStack {
                        Text("Smart Wrapper Card")
                            .font(.headline)
                        Spacer()
                        Button("Add to Wallet") {
                            showingWalletProvisioning = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    // Virtual card display
                    VStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(height: 200)
                            .overlay(
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        Text("SMART CARD")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.8))
                                        Spacer()
                                        Image(systemName: "wifi")
                                            .foregroundColor(.white)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("**** **** **** 1234")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                    
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("CARDHOLDER")
                                                .font(.caption2)
                                                .foregroundColor(.white.opacity(0.8))
                                            Text("JOHN DOE")
                                                .font(.caption)
                                                .foregroundColor(.white)
                                        }
                                        Spacer()
                                        VStack(alignment: .trailing, spacing: 4) {
                                            Text("EXPIRES")
                                                .font(.caption2)
                                                .foregroundColor(.white.opacity(0.8))
                                            Text("12/25")
                                                .font(.caption)
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                                .padding()
                            )
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                
                // Real Cards Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Your Real Cards")
                            .font(.headline)
                        Spacer()
                        Button("Add Card") {
                            showingAddCard = true
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    if cardManager.realCards.isEmpty {
                        Text("No cards added yet")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        ForEach(cardManager.realCards) { card in
                            CardRowView(card: card)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Smart Card")
            .sheet(isPresented: $showingAddCard) {
                AddCardView()
            }
            .sheet(isPresented: $showingWalletProvisioning) {
                WalletProvisioningView()
            }
        }
    }
}

struct CardRowView: View {
    let card: RealCard
    
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(cardColor)
                .frame(width: 40, height: 25)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(card.nickname)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("**** \(card.lastFour)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(card.cardType)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.systemGray5))
                .cornerRadius(4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var cardColor: Color {
        switch card.cardType.lowercased() {
        case "chase": return .blue
        case "amex": return .green
        case "visa": return .orange
        case "mastercard": return .red
        default: return .gray
        }
    }
}

struct TransactionsView: View {
    @EnvironmentObject var cardManager: CardManager
    @State private var transactions: [TransactionRoute] = []
    
    var body: some View {
        NavigationView {
            List {
                if transactions.isEmpty {
                    Text("No transactions yet")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(transactions) { transaction in
                        TransactionRowView(transaction: transaction)
                    }
                }
            }
            .navigationTitle("Transactions")
            .refreshable {
                await loadTransactions()
            }
            .onAppear {
                Task {
                    await loadTransactions()
                }
            }
        }
    }
    
    private func loadTransactions() async {
        // Mock transactions for MVP
        transactions = [
            TransactionRoute(
                id: "1",
                transactionId: "txn_123",
                amount: 2500,
                currency: "usd",
                mcc: "5812",
                merchantName: "Starbucks",
                routedToCard: "chase_sapphire",
                timestamp: Date()
            ),
            TransactionRoute(
                id: "2",
                transactionId: "txn_124",
                amount: 15000,
                currency: "usd",
                mcc: "3000",
                merchantName: "United Airlines",
                routedToCard: "amex_platinum",
                timestamp: Date().addingTimeInterval(-86400)
            ),
            TransactionRoute(
                id: "3",
                transactionId: "txn_125",
                amount: 8500,
                currency: "usd",
                mcc: "5411",
                merchantName: "Whole Foods",
                routedToCard: "amex_gold",
                timestamp: Date().addingTimeInterval(-172800)
            )
        ]
    }
}

struct TransactionRowView: View {
    let transaction: TransactionRoute
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(transaction.merchantName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(formatDate(transaction.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatAmount(transaction.amount))
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(transaction.routedToCard.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            HStack {
                Text("MCC: \(transaction.mcc)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text(transaction.currency.uppercased())
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatAmount(_ amount: Int) -> String {
        let dollars = Double(amount) / 100.0
        return String(format: "$%.2f", dollars)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationView {
            List {
                Section("Account") {
                    HStack {
                        Text("Email")
                        Spacer()
                        Text(authManager.currentUser?.email ?? "demo@example.com")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Routing Rules") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Routing Logic:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• Dining (MCC 5812) → Chase Sapphire")
                            Text("• Travel (MCC 3000-3999) → Amex Platinum")
                            Text("• Gas (MCC 5541) → Amex Gold")
                            Text("• Groceries (MCC 5411) → Amex Gold")
                            Text("• Everything else → Default card")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                Section {
                    Button("Sign Out") {
                        authManager.signOut()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    ContentView()
}