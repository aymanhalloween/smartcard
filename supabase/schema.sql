-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create users table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.users (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    name TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create real cards table
CREATE TABLE IF NOT EXISTS public.real_cards (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    nickname TEXT NOT NULL,
    card_type TEXT NOT NULL,
    last_four TEXT NOT NULL,
    token TEXT NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create virtual cards table
CREATE TABLE IF NOT EXISTS public.virtual_cards (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    stripe_card_id TEXT UNIQUE NOT NULL,
    last_four TEXT NOT NULL,
    status TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create transaction routes table
CREATE TABLE IF NOT EXISTS public.transaction_routes (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    transaction_id TEXT UNIQUE NOT NULL,
    amount INTEGER NOT NULL,
    currency TEXT NOT NULL,
    mcc TEXT,
    merchant_name TEXT,
    routed_to_card TEXT NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_real_cards_user_id ON public.real_cards(user_id);
CREATE INDEX IF NOT EXISTS idx_virtual_cards_user_id ON public.virtual_cards(user_id);
CREATE INDEX IF NOT EXISTS idx_transaction_routes_timestamp ON public.transaction_routes(timestamp);

-- Enable Row Level Security (RLS)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.real_cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.virtual_cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transaction_routes ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
-- Users can only see their own data
CREATE POLICY "Users can view own profile" ON public.users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.users
    FOR UPDATE USING (auth.uid() = id);

-- Real cards policies
CREATE POLICY "Users can view own real cards" ON public.real_cards
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own real cards" ON public.real_cards
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own real cards" ON public.real_cards
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own real cards" ON public.real_cards
    FOR DELETE USING (auth.uid() = user_id);

-- Virtual cards policies
CREATE POLICY "Users can view own virtual cards" ON public.virtual_cards
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own virtual cards" ON public.virtual_cards
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own virtual cards" ON public.virtual_cards
    FOR UPDATE USING (auth.uid() = user_id);

-- Transaction routes policies (read-only for users)
CREATE POLICY "Users can view transaction routes" ON public.transaction_routes
    FOR SELECT USING (true);

-- Create function to handle user creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, email, name)
    VALUES (NEW.id, NEW.email, NEW.raw_user_meta_data->>'name');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for new user creation
CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Insert some sample data for testing
INSERT INTO public.users (id, email, name) VALUES 
    ('demo_user', 'demo@smartcard.com', 'Demo User')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.real_cards (user_id, nickname, card_type, last_four, token, is_active) VALUES 
    ('demo_user', 'Chase Sapphire', 'Chase', '1234', 'tok_chase_1234_1234567890', true),
    ('demo_user', 'Amex Platinum', 'Amex', '5678', 'tok_amex_5678_1234567890', true),
    ('demo_user', 'Amex Gold', 'Amex', '9012', 'tok_amex_9012_1234567890', true)
ON CONFLICT DO NOTHING;

INSERT INTO public.virtual_cards (user_id, stripe_card_id, last_four, status) VALUES 
    ('demo_user', 'card_1234567890', '1234', 'active')
ON CONFLICT DO NOTHING;

INSERT INTO public.transaction_routes (transaction_id, amount, currency, mcc, merchant_name, routed_to_card) VALUES 
    ('txn_123', 2500, 'usd', '5812', 'Starbucks', 'chase_sapphire'),
    ('txn_124', 15000, 'usd', '3000', 'United Airlines', 'amex_platinum'),
    ('txn_125', 8500, 'usd', '5411', 'Whole Foods', 'amex_gold')
ON CONFLICT DO NOTHING;