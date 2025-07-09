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
// 🎯 SMART CARD ROUTING LOGIC
// ==================================================

function selectCard(mcc, merchantName) {
  console.log(`🔍 [ROUTER] Analyzing MCC: ${mcc}, Merchant: ${merchantName}`);
  
  // Enhanced routing logic with more categories
  if (mcc === '5812' || mcc === '5813' || mcc === '5814') {
    console.log('🍽️  [ROUTER] Dining detected → Chase Sapphire (3x points)');
    return 'chase_sapphire';
  }
  
  // Travel MCCs (3000-3999)
  if (mcc >= '3000' && mcc <= '3999') {
    console.log('✈️  [ROUTER] Travel detected → Amex Platinum (5x points)');
    return 'amex_platinum';
  }
  
  // Gas stations
  if (mcc === '5541' || mcc === '5542') {
    console.log('⛽ [ROUTER] Gas detected → Amex Gold (4x points)');
    return 'amex_gold';
  }
  
  // Groceries
  if (mcc === '5411') {
    console.log('🛒 [ROUTER] Groceries detected → Amex Gold (4x points)');
    return 'amex_gold';
  }
  
  // Online shopping
  if (mcc === '5732' || mcc === '5734') {
    console.log('🛍️  [ROUTER] Online shopping detected → Chase Freedom');
    return 'chase_freedom';
  }
  
  // Streaming services
  if (mcc === '4899' || mcc === '5815') {
    console.log('📺 [ROUTER] Streaming/Digital services → Chase Freedom');
    return 'chase_freedom';
  }
  
  console.log('💳 [ROUTER] Default routing → Using default card');
  return 'default_card';
}

// Get the tokenized payment method for a selected card
function getRealCardToken(cardType) {
  // Mock card tokens - in production, these would be real tokenized cards
  const cardTokens = {
    'chase_sapphire': 'pm_card_chase_sapphire_1234',
    'amex_platinum': 'pm_card_amex_platinum_5678',
    'amex_gold': 'pm_card_amex_gold_9012',
    'chase_freedom': 'pm_card_chase_freedom_3456',
    'default_card': 'pm_card_default_7890'
  };
  
  return cardTokens[cardType] || cardTokens['default_card'];
}

// Create a mock payment (in production, this charges the real card)
async function createMockPayment(amount, currency, paymentMethodToken, merchantName) {
  console.log(`💰 [PAYMENT] Creating payment for $${(amount / 100).toFixed(2)} using ${paymentMethodToken}`);
  
  // For MVP, we simulate the payment without actually charging
  // In production, you would use the real payment method token
  try {
    // Mock payment intent - replace with real Stripe charge in production
    const mockPaymentIntent = {
      id: `pi_mock_${Date.now()}`,
      amount: amount,
      currency: currency,
      status: 'succeeded',
      payment_method: paymentMethodToken,
      description: `Smart Card routing to real card for ${merchantName}`
    };
    
    // Simulate processing time
    await new Promise(resolve => setTimeout(resolve, 100));
    
    console.log(`✅ [PAYMENT] Mock payment succeeded: ${mockPaymentIntent.id}`);
    return mockPaymentIntent;
    
    // In production, you would do:
    /*
    const paymentIntent = await stripe.paymentIntents.create({
      amount,
      currency,
      payment_method: paymentMethodToken,
      confirm: true,
      description: `Smart Card routing for ${merchantName}`,
      metadata: {
        original_merchant: merchantName,
        routing_decision: 'smart_wrapper_card'
      }
    });
    
    return paymentIntent;
    */
    
  } catch (error) {
    console.error(`❌ [PAYMENT] Payment failed:`, error.message);
    throw error;
  }
}

// Store the routing decision in the database
async function storeRoutingDecision(authId, amount, currency, mcc, merchantName, selectedCard, status) {
  try {
    const { error } = await supabase
      .from('transaction_routes')
      .insert({
        transaction_id: authId,
        amount: amount,
        currency: currency,
        mcc: mcc,
        merchant_name: merchantName,
        routed_to_card: selectedCard,
        status: status,
        timestamp: new Date().toISOString()
      });
    
    if (error) {
      console.error('❌ [DATABASE] Error storing routing decision:', error);
    } else {
      console.log(`✅ [DATABASE] Routing decision stored: ${authId} → ${selectedCard} (${status})`);
    }
  } catch (error) {
    console.error('❌ [DATABASE] Database error:', error);
  }
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

// 5. Smart Wrapper Card Routing Webhook
// Receives Stripe Issuing webhook -> routes to real card -> approves spend
app.post('/api/webhook', bodyParser.raw({ type: 'application/json' }), async (req, res) => {
  const sig = req.headers['stripe-signature'];
  let event;
  
  try {
    event = stripe.webhooks.constructEvent(req.body, sig, process.env.STRIPE_WEBHOOK_SECRET);
  } catch (err) {
    console.error('❌ Webhook signature verification failed:', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }
  
  console.log('📨 Webhook received:', event.type);
  
  // Handle real-time authorization events (the smart routing!)
  if (event.type === 'issuing_authorization.created') {
    const auth = event.data.object;
    const mcc = auth.merchant_data?.mcc;
    const merchantName = auth.merchant_data?.name || 'Unknown Merchant';
    const amount = auth.amount;
    const currency = auth.currency;
    
    console.log(`🔥 [SMART ROUTER] New transaction @ ${merchantName} (MCC: ${mcc}) for $${(amount / 100).toFixed(2)}`);
    
    // 1. Decide which real card to route to
    const selectedCard = selectCard(mcc, merchantName);
    const realCardToken = getRealCardToken(selectedCard);
    
    console.log(`🎯 [ROUTING] Selected card: ${selectedCard} (token: ${realCardToken})`);
    
    try {
      // 2. Forward charge to selected real card
      console.log(`💳 [CHARGING] Attempting to charge ${selectedCard}...`);
      
      // In production, this would charge the actual real card
      const paymentIntent = await createMockPayment(amount, currency, realCardToken, merchantName);
      
      console.log(`✅ [SUCCESS] Payment Intent created: ${paymentIntent.id}`);
      
      // 3. Approve the original virtual card transaction
      await stripe.issuing.authorizations.approve(auth.id);
      
      console.log(`✅ [APPROVED] Virtual card transaction ${auth.id} approved`);
      
      // 4. Store the routing decision
      await storeRoutingDecision(auth.id, amount, currency, mcc, merchantName, selectedCard, 'approved');
      
      return res.json({ 
        success: true, 
        routed_to: selectedCard,
        payment_intent: paymentIntent.id,
        status: 'approved'
      });

    } catch (err) {
      console.error(`❌ [ERROR] Failed to charge ${selectedCard}:`, err.message);

      try {
        // Decline the virtual card charge if real card fails
        await stripe.issuing.authorizations.decline(auth.id, {
          reason: 'insufficient_funds' // or 'suspected_fraud'
        });
        
        console.log(`❌ [DECLINED] Virtual card transaction ${auth.id} declined due to routing failure`);
        
        // Store the failed routing decision
        await storeRoutingDecision(auth.id, amount, currency, mcc, merchantName, selectedCard, 'declined');
        
      } catch (declineErr) {
        console.error(`❌ [ERROR] Failed to decline authorization:`, declineErr.message);
      }
      
      return res.status(500).json({ 
        success: false, 
        error: 'Routing failed',
        routed_to: selectedCard,
        status: 'declined'
      });
    }
  }
  
  // Handle completed transactions for logging
  if (event.type === 'issuing_transaction.created') {
    const transaction = event.data.object;
    
    console.log('📋 [COMPLETED] Transaction finalized:', {
      id: transaction.id,
      amount: transaction.amount,
      currency: transaction.currency,
      status: transaction.status,
      merchant: transaction.merchant_data?.name
    });
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