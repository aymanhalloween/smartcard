require('dotenv').config();
const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const { createClient } = require('@supabase/supabase-js');

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors());
app.use(bodyParser.json());

// Initialize Supabase
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_ANON_KEY
);

// ==================================================
// 🎯 CARD ROUTING LOGIC
// ==================================================

function selectCard(mcc, merchantName) {
  console.log(`🔍 Selecting card for MCC: ${mcc}, Merchant: ${merchantName}`);
  
  // Simple routing logic - hardcoded for MVP
  if (mcc === '5812' || mcc === '5813' || mcc === '5814') {
    console.log('🍽️  Dining detected → Routing to Chase Sapphire');
    return 'chase_sapphire';
  }
  
  // Travel MCCs (3000-3999)
  if (mcc >= '3000' && mcc <= '3999') {
    console.log('✈️  Travel detected → Routing to Amex Platinum');
    return 'amex_platinum';
  }
  
  // Gas stations
  if (mcc === '5541' || mcc === '5542') {
    console.log('⛽ Gas detected → Routing to Amex Gold');
    return 'amex_gold';
  }
  
  // Groceries
  if (mcc === '5411') {
    console.log('🛒 Groceries detected → Routing to Amex Gold');
    return 'amex_gold';
  }
  
  console.log('💳 Default routing → Using default card');
  return 'default_card';
}

// ==================================================
// 🚀 API ENDPOINTS
// ==================================================

// 1. Create virtual card for user
app.post('/api/create-virtual-card', async (req, res) => {
  try {
    const { userId, cardholderName } = req.body;
    
    console.log(`🎯 Creating virtual card for user: ${userId}`);
    
    // Create virtual card via Stripe Issuing
    const card = await stripe.issuing.cards.create({
      cardholder: cardholderName || 'Smart Card User',
      currency: 'usd',
      type: 'virtual',
      status: 'active',
      shipping: {
        name: cardholderName || 'Smart Card User',
        address: {
          line1: '123 Main St',
          city: 'San Francisco',
          state: 'CA',
          postal_code: '94102',
          country: 'US',
        },
      },
    });
    
    // Store card info in Supabase (mock for now)
    const { error } = await supabase
      .from('virtual_cards')
      .insert({
        user_id: userId,
        stripe_card_id: card.id,
        last_four: card.last4,
        status: card.status
      });
    
    if (error) {
      console.error('Supabase error:', error);
    }
    
    res.json({
      success: true,
      card: {
        id: card.id,
        last4: card.last4,
        status: card.status
      }
    });
    
  } catch (error) {
    console.error('Error creating virtual card:', error);
    res.status(500).json({ error: error.message });
  }
});

// 2. Apple Wallet provisioning endpoint
app.post('/api/create-wallet-pass', async (req, res) => {
  try {
    const { nonce, nonceSignature, certificates, cardId } = req.body;
    
    console.log('📱 Creating Apple Wallet pass for card:', cardId);
    
    // Create Apple Pay pass via Stripe
    const walletPass = await stripe.issuing.cards.createApplePayPass(
      cardId,
      {
        certificates: certificates,
        nonce: nonce,
        nonce_signature: nonceSignature,
      }
    );
    
    res.json({
      activationData: walletPass.activation_data,
      encryptedPassData: walletPass.encrypted_pass,
      ephemeralPublicKey: walletPass.ephemeral_public_key,
    });
    
  } catch (error) {
    console.error('Error creating wallet pass:', error);
    res.status(500).json({ error: error.message });
  }
});

// 3. Add real card (mock tokens for MVP)
app.post('/api/add-real-card', async (req, res) => {
  try {
    const { userId, cardNickname, cardType, lastFour } = req.body;
    
    console.log(`💳 Adding real card: ${cardNickname} for user: ${userId}`);
    
    // Mock token - in production this would be a real tokenized card
    const mockToken = `tok_${cardType}_${lastFour}_${Date.now()}`;
    
    // Store in Supabase
    const { data, error } = await supabase
      .from('real_cards')
      .insert({
        user_id: userId,
        nickname: cardNickname,
        card_type: cardType,
        last_four: lastFour,
        token: mockToken,
        is_active: true
      })
      .select();
    
    if (error) {
      console.error('Supabase error:', error);
      return res.status(500).json({ error: error.message });
    }
    
    res.json({
      success: true,
      card: {
        id: data[0].id,
        nickname: cardNickname,
        cardType: cardType,
        lastFour: lastFour
      }
    });
    
  } catch (error) {
    console.error('Error adding real card:', error);
    res.status(500).json({ error: error.message });
  }
});

// 4. Get user's cards
app.get('/api/user-cards/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    
    // Get real cards
    const { data: realCards, error: realCardsError } = await supabase
      .from('real_cards')
      .select('*')
      .eq('user_id', userId)
      .eq('is_active', true);
    
    if (realCardsError) {
      console.error('Error fetching real cards:', realCardsError);
    }
    
    // Get virtual card
    const { data: virtualCards, error: virtualCardsError } = await supabase
      .from('virtual_cards')
      .select('*')
      .eq('user_id', userId);
    
    if (virtualCardsError) {
      console.error('Error fetching virtual cards:', virtualCardsError);
    }
    
    res.json({
      realCards: realCards || [],
      virtualCards: virtualCards || []
    });
    
  } catch (error) {
    console.error('Error fetching user cards:', error);
    res.status(500).json({ error: error.message });
  }
});

// 5. Stripe webhook for transaction events
app.post('/api/webhook', bodyParser.raw({ type: 'application/json' }), async (req, res) => {
  const sig = req.headers['stripe-signature'];
  let event;
  
  try {
    event = stripe.webhooks.constructEvent(req.body, sig, process.env.STRIPE_WEBHOOK_SECRET);
  } catch (err) {
    console.error('Webhook signature verification failed:', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }
  
  console.log('📨 Webhook received:', event.type);
  
  // Handle transaction events
  if (event.type === 'issuing_transaction.created') {
    const transaction = event.data.object;
    
    console.log('💳 Transaction created:', {
      id: transaction.id,
      amount: transaction.amount,
      currency: transaction.currency,
      merchant_data: transaction.merchant_data
    });
    
    // Extract MCC and merchant info
    const mcc = transaction.merchant_data?.mcc;
    const merchantName = transaction.merchant_data?.name || 'Unknown Merchant';
    
    // Route the transaction
    const selectedCard = selectCard(mcc, merchantName);
    
    console.log(`🎯 Transaction ${transaction.id} routed to: ${selectedCard}`);
    
    // In a real implementation, you would:
    // 1. Look up the actual card token for the selected card
    // 2. Forward the transaction to that card
    // 3. Store the routing decision in your database
    
    // For MVP, just log the decision
    const { error } = await supabase
      .from('transaction_routes')
      .insert({
        transaction_id: transaction.id,
        amount: transaction.amount,
        currency: transaction.currency,
        mcc: mcc,
        merchant_name: merchantName,
        routed_to_card: selectedCard,
        timestamp: new Date().toISOString()
      });
    
    if (error) {
      console.error('Error storing transaction route:', error);
    }
  }
  
  res.json({ received: true });
});

// 6. Get transaction history
app.get('/api/transactions/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    
    // Get routing history from Supabase
    const { data: routes, error } = await supabase
      .from('transaction_routes')
      .select('*')
      .order('timestamp', { ascending: false })
      .limit(50);
    
    if (error) {
      console.error('Error fetching transactions:', error);
      return res.status(500).json({ error: error.message });
    }
    
    res.json({ transactions: routes || [] });
    
  } catch (error) {
    console.error('Error fetching transaction history:', error);
    res.status(500).json({ error: error.message });
  }
});

// ==================================================
// 🏃‍♂️ SERVER STARTUP
// ==================================================

app.listen(PORT, () => {
  console.log(`🚀 Smart Card Backend running on port ${PORT}`);
  console.log(`📱 Apple Wallet endpoint: http://localhost:${PORT}/api/create-wallet-pass`);
  console.log(`💳 Virtual card endpoint: http://localhost:${PORT}/api/create-virtual-card`);
  console.log(`🔔 Webhook endpoint: http://localhost:${PORT}/api/webhook`);
});

module.exports = app;