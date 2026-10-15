-- Supabase SQL Schema for AI Chat Analyser
-- Security: chat text and receipts are strictly kept client-side.
-- Server tables track only operational metadata, rate limits, and model config.

-- 1. Model Configuration Table
CREATE TABLE IF NOT EXISTS public.model_config (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider TEXT NOT NULL DEFAULT 'gemini',
    model_id TEXT NOT NULL DEFAULT 'gemini-1.5-flash',
    is_active BOOLEAN NOT NULL DEFAULT true,
    input_cost_per_m NUMERIC(10, 4) NOT NULL DEFAULT 0.075,
    output_cost_per_m NUMERIC(10, 4) NOT NULL DEFAULT 0.30,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Seed default active model configuration
INSERT INTO public.model_config (provider, model_id, is_active, input_cost_per_m, output_cost_per_m)
VALUES ('gemini', 'gemini-1.5-flash', true, 0.0750, 0.3000)
ON CONFLICT DO NOTHING;

-- 2. Analysis Usage Accounting (Minimal metadata: tokens, costs, timestamps)
CREATE TABLE IF NOT EXISTS public.analysis_usage (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL,
    analysis_type TEXT NOT NULL,
    input_tokens INT NOT NULL DEFAULT 0,
    output_tokens INT NOT NULL DEFAULT 0,
    cost_usd NUMERIC(8, 5) NOT NULL DEFAULT 0.00000,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Index for weekly usage lookup
CREATE INDEX IF NOT EXISTS idx_analysis_usage_user_week 
ON public.analysis_usage(user_id, created_at);

-- 3. Row Level Security Policies
ALTER TABLE public.model_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.analysis_usage ENABLE ROW LEVEL SECURITY;

-- Allow anonymous or authenticated clients to read active model config
CREATE POLICY "Allow public read on active model_config"
ON public.model_config FOR SELECT
USING (is_active = true);

-- Allow users to read their own usage history
CREATE POLICY "Allow users to read their own usage"
ON public.analysis_usage FOR SELECT
USING (auth.uid()::text = user_id OR user_id = current_setting('request.headers', true)::json->>'x-anonymous-user-id');

-- Service role full access for Edge Functions
CREATE POLICY "Service role full access on usage"
ON public.analysis_usage FOR ALL
TO service_role
USING (true)
WITH CHECK (true);
