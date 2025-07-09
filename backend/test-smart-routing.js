#!/usr/bin/env node

// Smart Card Routing Test Script
// Simulates Stripe Issuing webhook events to test the routing logic

const axios = require('axios');

const WEBHOOK_URL = 'http://localhost:3001/api/webhook';

// Test scenarios with different MCCs
const testScenarios = [
  {
    name: 'Starbucks Coffee Purchase',
    mcc: '5812',
    merchant: 'Starbucks #1234',
    amount: 525, // $5.25
    expectedCard: 'chase_sapphire'
  },
  {
    name: 'United Airlines Flight',
    mcc: '3000',
    merchant: 'United Airlines',
    amount: 45000, // $450.00
    expectedCard: 'amex_platinum'
  },
  {
    name: 'Shell Gas Station',
    mcc: '5541',
    merchant: 'Shell #5678',
    amount: 4500, // $45.00
    expectedCard: 'amex_gold'
  },
  {
    name: 'Whole Foods Groceries',
    mcc: '5411',
    merchant: 'Whole Foods Market',
    amount: 8750, // $87.50
    expectedCard: 'amex_gold'
  },
  {
    name: 'Amazon Online Purchase',
    mcc: '5732',
    merchant: 'Amazon.com',
    amount: 2999, // $29.99
    expectedCard: 'chase_freedom'
  },
  {
    name: 'Netflix Subscription',
    mcc: '4899',
    merchant: 'Netflix',
    amount: 1599, // $15.99
    expectedCard: 'chase_freedom'
  },
  {
    name: 'Unknown Merchant',
    mcc: '9999',
    merchant: 'Random Store',
    amount: 1000, // $10.00
    expectedCard: 'default_card'
  }
];

// Create a mock Stripe webhook event
function createWebhookEvent(scenario) {
  return {
    id: `evt_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
    object: 'event',
    type: 'issuing_authorization.created',
    created: Math.floor(Date.now() / 1000),
    data: {
      object: {
        id: `iauth_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
        object: 'issuing.authorization',
        amount: scenario.amount,
        currency: 'usd',
        merchant_data: {
          mcc: scenario.mcc,
          name: scenario.merchant,
          city: 'San Francisco',
          state: 'CA',
          country: 'US'
        },
        status: 'pending',
        card: {
          id: 'ic_1234567890abcdef',
          last4: '1234'
        }
      }
    }
  };
}

// Test a single scenario
async function testScenario(scenario, index) {
  console.log(`\n🧪 Test ${index + 1}: ${scenario.name}`);
  console.log(`   MCC: ${scenario.mcc} | Amount: $${(scenario.amount / 100).toFixed(2)} | Expected: ${scenario.expectedCard}`);
  
  const webhookEvent = createWebhookEvent(scenario);
  
  try {
    const response = await axios.post(WEBHOOK_URL, webhookEvent, {
      headers: {
        'Content-Type': 'application/json',
        'Stripe-Signature': 'whsec_test_signature' // Mock signature for testing
      },
      timeout: 5000
    });
    
    if (response.status === 200) {
      const result = response.data;
      if (result.success && result.routed_to === scenario.expectedCard) {
        console.log(`   ✅ SUCCESS: Routed to ${result.routed_to} (${result.status})`);
        if (result.payment_intent) {
          console.log(`   💳 Payment Intent: ${result.payment_intent}`);
        }
      } else if (result.success) {
        console.log(`   ⚠️  UNEXPECTED: Routed to ${result.routed_to}, expected ${scenario.expectedCard}`);
      } else {
        console.log(`   ❌ FAILED: ${result.error || 'Unknown error'}`);
      }
    } else {
      console.log(`   ❌ HTTP ERROR: ${response.status}`);
    }
    
  } catch (error) {
    if (error.code === 'ECONNREFUSED') {
      console.log(`   ❌ CONNECTION ERROR: Backend server not running on ${WEBHOOK_URL}`);
    } else {
      console.log(`   ❌ ERROR: ${error.message}`);
    }
  }
  
  // Small delay between tests
  await new Promise(resolve => setTimeout(resolve, 200));
}

// Run all test scenarios
async function runTests() {
  console.log('🔥 Smart Card Routing Test Suite');
  console.log('=================================');
  console.log(`Testing webhook endpoint: ${WEBHOOK_URL}`);
  
  for (let i = 0; i < testScenarios.length; i++) {
    await testScenario(testScenarios[i], i);
  }
  
  console.log('\n🏁 Test suite completed!');
  console.log('\nTo see detailed routing logs, check your backend console.');
}

// Handle command line execution
if (require.main === module) {
  runTests().catch(error => {
    console.error('❌ Test suite failed:', error.message);
    process.exit(1);
  });
}

module.exports = { testScenarios, createWebhookEvent, testScenario }; 