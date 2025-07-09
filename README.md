# Smart Card MVP

A smart credit card wrapper that automatically routes transactions to your best rewards card based on merchant category codes (MCC).

## 🎯 Concept

This MVP creates a virtual card (via Stripe Issuing) that acts as a single interface to all your existing credit cards. When you make a purchase, the system automatically routes the transaction to the card that gives you the most rewards, points, or cashback for that specific merchant category.

## 🏗️ Architecture

### Backend (Next.js API Routes)
- **Stripe Issuing Integration**: Creates virtual cards and enables Apple Wallet provisioning
- **Transaction Routing**: Simple MCC-based logic to select the best card
- **Webhook Handler**: Processes Stripe transaction events
- **Supabase Integration**: User auth and card storage

### Frontend (iOS SwiftUI)
- **User Authentication**: Email login via Supabase
- **Card Management**: Add and manage real cards with nicknames
- **Apple Wallet Integration**: Provision virtual card using `PKAddPaymentPassViewController`
- **Transaction History**: View spending patterns and routing decisions

### Routing Logic
```
- Dining (MCC 5812) → Chase Sapphire (3x points)
- Travel (MCC 3000-3999) → Amex Platinum (5x points)  
- Everything else → Default card
```

## 🚀 Quick Start

### Prerequisites
- Node.js 18+
- iOS 15+ (for Apple Wallet integration)
- Stripe account with Issuing enabled
- Supabase project

### Backend Setup
```bash
cd backend
npm install
cp .env.example .env
# Add your Stripe and Supabase keys
npm run dev
```

### iOS App Setup
```bash
cd ios-app
# Open in Xcode
# Add your Stripe publishable key
# Build and run
```

## 📁 Project Structure

```
smartcard/
├── backend/                 # Next.js API routes
│   ├── pages/api/          # API endpoints
│   ├── lib/                # Stripe, Supabase, routing logic
│   └── package.json
├── ios-app/                # SwiftUI iOS app
│   ├── SmartCard/          # Main app files
│   ├── Views/              # SwiftUI views
│   └── Models/             # Data models
└── README.md
```

## 🔧 Environment Variables

```env
# Stripe
STRIPE_SECRET_KEY=sk_test_...
STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...

# Supabase
SUPABASE_URL=https://...
SUPABASE_ANON_KEY=eyJ...
```

## 🧪 Testing

This is a lightweight MVP designed for fast iteration:
- Manual testing and debugging
- Minimal abstractions
- Clear, readable code
- No complex CI/CD or Docker setup

## 📝 Development Notes

- Keep backend routes in single files where possible
- Use simple, descriptive variable names
- Hardcode routing rules for now (no database config)
- Mock card tokens for MVP phase
- Focus on core functionality over fancy features

## 🔮 Future Enhancements

- Machine learning for better routing decisions
- Real card tokenization
- Advanced analytics dashboard
- Multi-platform support (Android, web)
- Custom routing rules per user

## 📄 License

MIT License - feel free to use this for learning and experimentation. 