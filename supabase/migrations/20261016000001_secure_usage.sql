-- Secure fair-use accounting now that every install signs in anonymously.
-- The old policy trusted a client-supplied header, which anyone could fake.
DROP POLICY IF EXISTS "Allow users to read their own usage" ON public.analysis_usage;

CREATE POLICY "Users read their own usage"
ON public.analysis_usage FOR SELECT
TO authenticated
USING (auth.uid()::text = user_id);

-- Fast "how many reports today for everyone" check (global daily cap).
CREATE INDEX IF NOT EXISTS idx_analysis_usage_created
ON public.analysis_usage(created_at);

-- Remove rows written by the pre-login test calls.
DELETE FROM public.analysis_usage WHERE user_id IN ('claude-test', 'anon_default');
