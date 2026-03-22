-- =============================================================================
-- Grant admin access to the account identified by phone 09276319866.
-- Run this in Supabase SQL Editor if that account lost admin after migration 003.
--
-- Optional: run this first to see which row will be updated:
--   SELECT user_id, phone, email, is_admin FROM public.profiles
--   WHERE phone LIKE '%9276319866%' OR email ILIKE '%09276319866%';
-- =============================================================================

UPDATE public.profiles
SET is_admin = true, updated_at = now()
WHERE phone LIKE '%9276319866%'
   OR phone LIKE '%09276319866%'
   OR email ILIKE '%n09276319866%'
   OR email ILIKE '%09276319866%';
