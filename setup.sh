#!/bin/bash

echo "🚀 Setting up Smart Card MVP..."

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 18+ first."
    exit 1
fi

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo "❌ npm is not installed. Please install npm first."
    exit 1
fi

echo "✅ Node.js and npm are installed"

# Install backend dependencies
echo "📦 Installing backend dependencies..."
cd backend
npm install
cd ..

echo "✅ Backend dependencies installed"

# Create .env file if it doesn't exist
if [ ! -f "backend/.env" ]; then
    echo "📝 Creating .env file..."
    cp backend/.env.example backend/.env
    echo "⚠️  Please update backend/.env with your actual API keys"
else
    echo "✅ .env file already exists"
fi

echo ""
echo "🎉 Setup complete!"
echo ""
echo "Next steps:"
echo "1. Update backend/.env with your Stripe and Supabase keys"
echo "2. Run 'cd backend && npm run dev' to start the backend server"
echo "3. Open ios-app/SmartCardApp.xcodeproj in Xcode"
echo "4. Build and run the iOS app on a device or simulator"
echo ""
echo "For Apple Wallet integration:"
echo "- You'll need an Apple Developer account"
echo "- Configure Wallet capabilities in Xcode"
echo "- Set up Stripe Issuing with Apple Pay certificates"
echo ""