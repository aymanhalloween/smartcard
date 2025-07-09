# Smart Card Backend

Express.js backend for the Smart Card MVP with Stripe Issuing and Apple Wallet integration.

## 🚀 Quick Start

1. Install dependencies:
```bash
npm install
```

2. Copy environment variables:
```bash
cp .env.example .env
```

3. Update `.env` with your API keys:
```env
STRIPE_SECRET_KEY=sk_test_your_key_here
STRIPE_PUBLISHABLE_KEY=pk_test_your_key_here
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret_here
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_supabase_anon_key_here
```

4. Start the development server:
```bash
npm run dev
```

The server will start on `http://localhost:3001`

## 📡 API Endpoints

### Authentication & Users
- `POST /api/create-virtual-card` - Create a new virtual card
- `GET /api/user-cards/:userId` - Get user's cards
- `POST /api/add-real-card` - Add a real card

### Apple Wallet Integration
- `POST /api/create-wallet-pass` - Provision card to Apple Wallet

### Transactions & Webhooks
- `POST /api/webhook` - Stripe webhook for transaction events
- `GET /api/transactions/:userId` - Get transaction history

## 🎯 Smart Card Routing Logic

The backend implements intelligent MCC-based routing with real-time transaction processing:

### How It Works
1. **User pays** with virtual card in Apple Wallet
2. **Stripe Issuing** sends `issuing_authorization.created` webhook
3. **Smart Router** analyzes MCC and selects best real card
4. **Payment Processor** charges the selected real card
5. **Authorization** approves or declines the virtual card transaction

### Routing Rules
```javascript
function selectCard(mcc, merchantName) {
  // Dining (MCC 5812, 5813, 5814) → Chase Sapphire (3x points)
  if (mcc === '5812' || mcc === '5813' || mcc === '5814') {
    return 'chase_sapphire';
  }
  
  // Travel (MCC 3000-3999) → Amex Platinum (5x points)
  if (mcc >= '3000' && mcc <= '3999') {
    return 'amex_platinum';
  }
  
  // Gas (MCC 5541, 5542) → Amex Gold (4x points)
  if (mcc === '5541' || mcc === '5542') {
    return 'amex_gold';
  }
  
  // Groceries (MCC 5411) → Amex Gold (4x points)
  if (mcc === '5411') {
    return 'amex_gold';
  }
  
  // Online Shopping (MCC 5732, 5734) → Chase Freedom
  if (mcc === '5732' || mcc === '5734') {
    return 'chase_freedom';
  }
  
  // Streaming/Digital (MCC 4899, 5815) → Chase Freedom
  if (mcc === '4899' || mcc === '5815') {
    return 'chase_freedom';
  }
  
  // Default → Default card
  return 'default_card';
}
```

### Real-Time Processing
- **Authorization Time**: < 100ms typical response
- **Fallback Handling**: Auto-decline if real card fails
- **Logging**: Complete audit trail of routing decisions
- **Status Tracking**: Approved/Declined/Pending states

## 🔧 Stripe Setup

1. **Enable Stripe Issuing** in your Stripe dashboard
2. **Create a cardholder** for testing
3. **Set up webhooks** for `issuing_transaction.created` events
4. **Configure Apple Pay certificates** for wallet provisioning

### Webhook Configuration
```bash
stripe listen --forward-to localhost:3001/api/webhook
```

## 🗄️ Database Schema

The backend uses Supabase with these tables:
- `users` - User profiles
- `real_cards` - User's real credit cards
- `virtual_cards` - Stripe-issued virtual cards
- `transaction_routes` - Transaction routing history

## 🧪 Testing

### Smart Routing Test Suite
Run the comprehensive test suite to verify routing logic:
```bash
npm run test-routing
```

This will test 7 different scenarios:
- ☕ Starbucks (Dining) → Chase Sapphire
- ✈️ United Airlines (Travel) → Amex Platinum  
- ⛽ Shell (Gas) → Amex Gold
- 🛒 Whole Foods (Groceries) → Amex Gold
- 📦 Amazon (Online) → Chase Freedom
- 📺 Netflix (Streaming) → Chase Freedom
- ❓ Unknown Merchant → Default Card

### Manual Webhook Testing
Test smart authorization webhook:
```bash
curl -X POST http://localhost:3001/api/webhook \
  -H "Content-Type: application/json" \
  -d '{
    "type": "issuing_authorization.created",
    "data": {
      "object": {
        "id": "iauth_test_123",
        "amount": 2500,
        "currency": "usd",
        "merchant_data": {
          "mcc": "5812",
          "name": "Starbucks"
        },
        "status": "pending"
      }
    }
  }'
```

Expected response:
```json
{
  "success": true,
  "routed_to": "chase_sapphire",
  "payment_intent": "pi_mock_...",
  "status": "approved"
}
```

### Test Card Creation
```bash
curl -X POST http://localhost:3001/api/create-virtual-card \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "demo_user",
    "cardholderName": "Test User"
  }'
```

### Monitor Routing Logs
Start the server and watch real-time routing decisions:
```bash
npm run dev
```

Look for these log patterns:
- `🔥 [SMART ROUTER]` - New transaction detected
- `🎯 [ROUTING]` - Card selection decision
- `💳 [CHARGING]` - Real card charge attempt
- `✅ [APPROVED]` - Virtual card authorization approved

## 🔒 Security Notes

- All endpoints use CORS for cross-origin requests
- Webhook signatures are verified using Stripe's webhook secret
- Row Level Security (RLS) is enabled in Supabase
- Card tokens are mocked for MVP (use real tokenization in production)

## 🚀 Production Deployment

1. Set `NODE_ENV=production` in environment
2. Use a production database (Supabase)
3. Configure proper CORS origins
4. Set up SSL/TLS certificates
5. Use a process manager like PM2

## 📝 Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `STRIPE_SECRET_KEY` | Stripe secret key | Yes |
| `STRIPE_PUBLISHABLE_KEY` | Stripe publishable key | Yes |
| `STRIPE_WEBHOOK_SECRET` | Webhook signature secret | Yes |
| `SUPABASE_URL` | Supabase project URL | Yes |
| `SUPABASE_ANON_KEY` | Supabase anonymous key | Yes |
| `PORT` | Server port (default: 3001) | No |
| `NODE_ENV` | Environment (development/production) | No |

## 🔮 Future Enhancements

- Real card tokenization
- Machine learning for better routing
- Advanced analytics
- Multi-currency support
- Custom routing rules per user