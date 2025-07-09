# Smart Card iOS App

SwiftUI iOS app for the Smart Card MVP with Apple Wallet integration.

## 🚀 Quick Start

1. **Open the project in Xcode:**
```bash
open ios-app/SmartCardApp.xcodeproj
```

2. **Configure your development team:**
   - Select the project in Xcode
   - Go to "Signing & Capabilities"
   - Select your development team
   - Update the bundle identifier if needed

3. **Add Apple Wallet capability:**
   - In "Signing & Capabilities" tab
   - Click "+ Capability"
   - Add "Wallet" capability

4. **Build and run:**
   - Select a device or simulator
   - Press Cmd+R to build and run

## 📱 Features

### Authentication
- Mock login system (demo mode)
- User profile management
- Session persistence

### Card Management
- Add real credit cards with nicknames
- View virtual card details
- Card status and information display

### Apple Wallet Integration
- Add virtual card to Apple Wallet
- Contactless payment support
- PassKit integration

### Transaction History
- View transaction routing decisions
- MCC-based categorization
- Spending analytics

## 🏗️ Architecture

### Views
- `ContentView` - Main app container
- `LoginView` - Authentication screen
- `CardsView` - Card management
- `TransactionsView` - Transaction history
- `SettingsView` - App settings
- `AddCardView` - Add new card form
- `WalletProvisioningView` - Apple Wallet setup

### Models
- `User` - User profile data
- `RealCard` - User's real credit cards
- `VirtualCard` - Stripe-issued virtual cards
- `TransactionRoute` - Transaction routing data

### Managers
- `AuthManager` - Authentication state
- `CardManager` - Card operations
- `APIManager` - Backend communication

## 🔧 Configuration

### Backend URL
Update the backend URL in `Managers.swift`:
```swift
private let baseURL = "http://localhost:3001/api"
```

### Apple Wallet Setup
1. **Apple Developer Account:**
   - Enable Wallet capability
   - Create Apple Pay certificates
   - Configure payment processing

2. **Stripe Configuration:**
   - Set up Apple Pay in Stripe dashboard
   - Upload certificates to Stripe
   - Configure payment networks

3. **Xcode Configuration:**
   - Add Wallet entitlement
   - Configure bundle identifier
   - Set up provisioning profiles

## 🧪 Testing

### Simulator Testing
- Most features work in iOS Simulator
- Apple Wallet requires a physical device
- Use demo login for quick testing

### Device Testing
- Apple Wallet integration requires real device
- Test contactless payments
- Verify transaction routing

### Mock Data
The app includes mock data for development:
- Demo user account
- Sample credit cards
- Mock transaction history

## 📋 Requirements

- iOS 17.0+
- Xcode 15.0+
- Apple Developer Account (for Wallet)
- Physical device for Apple Wallet testing

## 🔒 Security

- Card tokens are mocked for MVP
- No sensitive data stored locally
- API communication over HTTPS
- Apple Pay security handled by system

## 🚀 Production Deployment

1. **Code Signing:**
   - Configure production certificates
   - Set up App Store distribution
   - Test on multiple devices

2. **Backend Integration:**
   - Update API endpoints to production
   - Configure proper authentication
   - Set up monitoring and analytics

3. **Apple Wallet:**
   - Submit for Apple Pay review
   - Configure production certificates
   - Test end-to-end payment flow

## 📝 Development Notes

### SwiftUI Best Practices
- Use `@StateObject` for managers
- `@EnvironmentObject` for shared state
- Async/await for API calls
- Proper error handling

### Apple Wallet Integration
- Use `PKAddPaymentPassViewController`
- Handle certificate chain properly
- Implement proper delegate methods
- Test on physical devices

### API Communication
- Use `URLSession` for network calls
- Proper JSON encoding/decoding
- Error handling and retry logic
- Loading states and user feedback

## 🔮 Future Enhancements

- Real card tokenization
- Push notifications
- Advanced analytics
- Custom routing rules
- Multi-language support
- Dark mode optimization
- Accessibility improvements

## 🐛 Troubleshooting

### Common Issues

1. **Apple Wallet not working:**
   - Check device compatibility
   - Verify entitlements
   - Test on physical device

2. **Backend connection errors:**
   - Check backend server is running
   - Verify API endpoints
   - Check network connectivity

3. **Build errors:**
   - Clean build folder (Cmd+Shift+K)
   - Update Xcode to latest version
   - Check deployment target

### Debug Tips
- Use Xcode console for logging
- Test API endpoints with curl
- Verify environment variables
- Check network tab in Xcode