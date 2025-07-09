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

## 🎯 Card Routing Logic

The backend implements simple MCC-based routing:

```javascript
function selectCard(mcc, merchantName) {
  // Dining (MCC 5812, 5813, 5814) → Chase Sapphire
  if (mcc === '5812' || mcc === '5813' || mcc === '5814') {
    return 'chase_sapphire';
  }
  
  // Travel (MCC 3000-3999) → Amex Platinum
  if (mcc >= '3000' && mcc <= '3999') {
    return 'amex_platinum';
  }
  
  // Gas (MCC 5541, 5542) → Amex Gold
  if (mcc === '5541' || mcc === '5542') {
    return 'amex_gold';
  }
  
  // Groceries (MCC 5411) → Amex Gold
  if (mcc === '5411') {
    return 'amex_gold';
  }
  
  // Default → Default card
  return 'default_card';
}
```

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

### Test Transaction Webhook
```bash
curl -X POST http://localhost:3001/api/webhook \
  -H "Content-Type: application/json" \
  -H "Stripe-Signature: whsec_test" \
  -d '{
    "type": "issuing_transaction.created",
    "data": {
      "object": {
        "id": "txn_test",
        "amount": 2500,
        "currency": "usd",
        "merchant_data": {
          "mcc": "5812",
          "name": "Starbucks"
        }
      }
    }
  }'
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