-- =============================================================================
-- Store per-device push tokens (FCM)
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.user_push_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  token text NOT NULL,
  platform text NOT NULL DEFAULT 'unknown',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT user_push_tokens_user_token_unique UNIQUE (user_id, token)
);

ALTER TABLE public.user_push_tokens ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "user_push_tokens_select_own" ON public.user_push_tokens;
CREATE POLICY "user_push_tokens_select_own"
ON public.user_push_tokens
FOR SELECT
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "user_push_tokens_insert_own" ON public.user_push_tokens;
CREATE POLICY "user_push_tokens_insert_own"
ON public.user_push_tokens
FOR INSERT
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "user_push_tokens_update_own" ON public.user_push_tokens;
CREATE POLICY "user_push_tokens_update_own"
ON public.user_push_tokens
FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "user_push_tokens_delete_own" ON public.user_push_tokens;
CREATE POLICY "user_push_tokens_delete_own"
ON public.user_push_tokens
FOR DELETE
USING (auth.uid() = user_id);

-- Keep updated_at fresh.
DROP TRIGGER IF EXISTS set_user_push_tokens_updated_at ON public.user_push_tokens;
DROP FUNCTION IF EXISTS public.set_user_push_tokens_updated_at();
CREATE FUNCTION public.set_user_push_tokens_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER set_user_push_tokens_updated_at
BEFORE UPDATE ON public.user_push_tokens
FOR EACH ROW
EXECUTE FUNCTION public.set_user_push_tokens_updated_at();

