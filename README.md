# Smart Card MVP

A smart credit card wrapper that automatically routes transactions to your best rewards card based on merchant category codes (MCC).

## 🎯 Concept

This MVP creates a virtual card (via Stripe Issuing) that acts as a single interface to all your existing credit cards. When you make a purchase, the system automatically routes the transaction to the card that gives you the most rewards, points, or cashback for that specific merchant category.

## 🏗️ Architecture

### Backend (Node.js/Express)
- **Stripe Issuing Integration**: Creates virtual cards and enables Apple Wallet provisioning
- **Smart Transaction Routing**: Real-time MCC-based routing with authorization approval/decline
- **Webhook Handler**: Processes Stripe authorization events and routes to real cards
- **Payment Processing**: Charges selected real cards and manages transaction flow
- **Supabase Integration**: User auth and card storage

### Frontend (iOS SwiftUI)
- **User Authentication**: Mock login system with demo mode
- **Card Management**: Add and manage real cards with nicknames
- **Apple Wallet Integration**: Provision virtual card using `PKAddPaymentPassViewController`
- **Transaction History**: View spending patterns and routing decisions

### Routing Logic
```
- Dining (MCC 5812, 5813, 5814) → Chase Sapphire (3x points)
- Travel (MCC 3000-3999) → Amex Platinum (5x points)
- Gas (MCC 5541, 5542) → Amex Gold (4x points)
- Groceries (MCC 5411) → Amex Gold (4x points)
- Everything else → Default card
```

## 🚀 Quick Start

### Prerequisites
- Node.js 18+
- Xcode 15+ (for iOS development)
- Stripe account with Issuing enabled
- Supabase project
- Apple Developer account (for Apple Wallet)

### 1. Setup Project
```bash
# Clone and setup
git clone <repository>
cd smart-card-mvp

# Run setup script
chmod +x setup.sh
./setup.sh
```

### 2. Configure Environment
```bash
# Update backend environment
cd backend
cp .env.example .env
# Edit .env with your API keys
```

Required environment variables:
```env
STRIPE_SECRET_KEY=sk_test_your_key_here
STRIPE_PUBLISHABLE_KEY=pk_test_your_key_here
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret_here
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_supabase_anon_key_here
```

### 3. Setup Database
```bash
# Run Supabase schema
psql -h your-project.supabase.co -U postgres -d postgres -f supabase/schema.sql
```

### 4. Start Backend
```bash
cd backend
npm run dev
# Server runs on http://localhost:3001
```

### 5. Setup iOS App
```bash
# Open in Xcode
open ios-app/SmartCardApp.xcodeproj
```

In Xcode:
1. Select your development team
2. Add "Wallet" capability
3. Update bundle identifier if needed
4. Build and run on device/simulator

## 📁 Project Structure

```
smart-card-mvp/
├── backend/                    # Node.js/Express backend
│   ├── server.js              # Main server file
│   ├── package.json           # Dependencies
│   ├── .env.example          # Environment template
│   └── README.md             # Backend documentation
├── ios-app/                   # SwiftUI iOS app
│   ├── SmartCardApp/         # Main app files
│   │   ├── ContentView.swift # Main UI
│   │   ├── Models.swift      # Data models
│   │   ├── Managers.swift    # Business logic
│   │   └── AdditionalViews.swift # Supporting views
│   ├── SmartCardApp.xcodeproj/ # Xcode project
│   └── README.md             # iOS documentation
├── supabase/                  # Database setup
│   └── schema.sql            # Database schema
├── setup.sh                   # Setup script
└── README.md                  # This file
```

## 🔧 Configuration

### Stripe Setup
1. Enable Stripe Issuing in dashboard
2. Create a cardholder for testing
3. Set up webhooks for `issuing_transaction.created`
4. Configure Apple Pay certificates

### Supabase Setup
1. Create new project
2. Run schema.sql in SQL editor
3. Get project URL and anon key
4. Configure RLS policies

### Apple Wallet Setup
1. Enable Wallet capability in Xcode
2. Configure Apple Pay in Stripe
3. Upload certificates to Stripe
4. Test on physical device

## 🧪 Testing

### Backend Testing
```bash
# Test smart routing with comprehensive test suite
cd backend
npm run test-routing

# Test individual authorization webhook
curl -X POST http://localhost:3001/api/webhook \
  -H "Content-Type: application/json" \
  -d '{"type": "issuing_authorization.created", "data": {"object": {"id": "iauth_test", "amount": 2500, "currency": "usd", "merchant_data": {"mcc": "5812", "name": "Starbucks"}, "status": "pending"}}}'

# Test card creation
curl -X POST http://localhost:3001/api/create-virtual-card \
  -H "Content-Type: application/json" \
  -d '{"userId": "demo_user", "cardholderName": "Test User"}'
```

### iOS Testing
- Use demo login for quick testing
- Apple Wallet requires physical device
- Test transaction routing logic
- Verify API communication

## 📡 API Endpoints

- `POST /api/create-virtual-card` - Create virtual card
- `POST /api/create-wallet-pass` - Apple Wallet provisioning
- `POST /api/add-real-card` - Add real card
- `GET /api/user-cards/:userId` - Get user's cards
- `POST /api/webhook` - Stripe webhook handler
- `GET /api/transactions/:userId` - Transaction history

## � Security Notes

- Card tokens are mocked for MVP
- Webhook signatures verified
- Row Level Security enabled
- CORS configured for development
- Use HTTPS in production

## 🚀 Production Deployment

1. **Backend:**
   - Set `NODE_ENV=production`
   - Use production database
   - Configure SSL/TLS
   - Set up monitoring

2. **iOS App:**
   - Configure production certificates
   - Update API endpoints
   - Submit for App Store review
   - Test Apple Wallet integration

## 📝 Development Notes

- Keep code simple and readable
- Use descriptive variable names
- Mock data for fast iteration
- Focus on core functionality
- Manual testing for MVP phase

## 🔮 Future Enhancements

- Real card tokenization
- Machine learning routing
- Advanced analytics
- Multi-platform support
- Custom routing rules
- Push notifications
- Real-time transaction updates

## 🐛 Troubleshooting

### Common Issues
1. **Backend won't start:** Check Node.js version and dependencies
2. **iOS build errors:** Clean build folder, check deployment target
3. **Apple Wallet issues:** Test on physical device, verify entitlements
4. **API errors:** Check environment variables, verify backend is running

### Debug Tips
- Check console logs in both backend and iOS
- Use Stripe CLI for webhook testing
- Verify database connections
- Test API endpoints with curl

## 📄 License

MIT License - feel free to use this for learning and experimentation. 