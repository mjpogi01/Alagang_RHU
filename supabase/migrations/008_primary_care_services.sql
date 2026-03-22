-- =============================================================================
-- Alagang RHU – Primary care service categories and services (admin-managed).
-- Drives the user-facing "Primary Care Services" / Service Directory.
-- Run after 005 (uses current_user_is_admin()). Idempotent.
-- =============================================================================

-- Categories (e.g. "Mga Serbisyong Pangkomunidad", "Mga Serbisyo para sa Indibidwal")
CREATE TABLE IF NOT EXISTS public.primary_care_categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  color_hex text NOT NULL DEFAULT 'FFBBDEFB',
  icon_name text NOT NULL DEFAULT 'monitor_heart_outlined',
  sort_order int NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_primary_care_categories_sort ON public.primary_care_categories(sort_order);

COMMENT ON TABLE public.primary_care_categories IS 'Primary care service categories shown in the service directory.';

-- Services (items under each category)
CREATE TABLE IF NOT EXISTS public.primary_care_services (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id uuid NOT NULL REFERENCES public.primary_care_categories(id) ON DELETE CASCADE,
  name text NOT NULL,
  sort_order int NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_primary_care_services_category ON public.primary_care_services(category_id);

COMMENT ON TABLE public.primary_care_services IS 'Individual services under each primary care category.';

-- updated_at trigger for categories
DROP TRIGGER IF EXISTS primary_care_categories_updated_at ON public.primary_care_categories;
CREATE TRIGGER primary_care_categories_updated_at
  BEFORE UPDATE ON public.primary_care_categories
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- RLS: everyone authenticated can read; only admins can write
ALTER TABLE public.primary_care_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.primary_care_services ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated can view primary_care_categories" ON public.primary_care_categories;
CREATE POLICY "Authenticated can view primary_care_categories"
  ON public.primary_care_categories FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Admins can manage primary_care_categories" ON public.primary_care_categories;
CREATE POLICY "Admins can manage primary_care_categories"
  ON public.primary_care_categories FOR ALL TO authenticated
  USING (public.current_user_is_admin())
  WITH CHECK (public.current_user_is_admin());

DROP POLICY IF EXISTS "Authenticated can view primary_care_services" ON public.primary_care_services;
CREATE POLICY "Authenticated can view primary_care_services"
  ON public.primary_care_services FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Admins can manage primary_care_services" ON public.primary_care_services;
CREATE POLICY "Admins can manage primary_care_services"
  ON public.primary_care_services FOR ALL TO authenticated
  USING (public.current_user_is_admin())
  WITH CHECK (public.current_user_is_admin());

-- Optional seed: insert default categories and services if table is empty (run once).
INSERT INTO public.primary_care_categories (id, title, color_hex, icon_name, sort_order)
SELECT gen_random_uuid(), 'Mga Serbisyong Pangkomunidad', 'FFCCBC', 'group_outlined', 0
WHERE NOT EXISTS (SELECT 1 FROM public.primary_care_categories LIMIT 1);
INSERT INTO public.primary_care_categories (id, title, color_hex, icon_name, sort_order)
SELECT gen_random_uuid(), 'Mga Serbisyo para sa Indibidwal', 'FFBBDEFB', 'monitor_heart_outlined', 1
WHERE (SELECT count(*) FROM public.primary_care_categories) = 1;
INSERT INTO public.primary_care_categories (id, title, color_hex, icon_name, sort_order)
SELECT gen_random_uuid(), 'Pangangalaga sa Ina at Bagong Silang', 'FFF8BBD0', 'favorite_border', 2
WHERE (SELECT count(*) FROM public.primary_care_categories) = 2;
INSERT INTO public.primary_care_categories (id, title, color_hex, icon_name, sort_order)
SELECT gen_random_uuid(), 'Mga Serbisyo sa Nutrisyon', 'FFFFF59D', 'timelapse_outlined', 3
WHERE (SELECT count(*) FROM public.primary_care_categories) = 3;
INSERT INTO public.primary_care_categories (id, title, color_hex, icon_name, sort_order)
SELECT gen_random_uuid(), 'Mga Serbisyo sa Pagbabakuna', 'FFB2DFDB', 'vaccines_outlined', 4
WHERE (SELECT count(*) FROM public.primary_care_categories) = 4;

-- Seed services for the 5 default categories (by sort_order).
DO $$
DECLARE
  c1 uuid; c2 uuid; c3 uuid; c4 uuid; c5 uuid;
BEGIN
  SELECT id INTO c1 FROM public.primary_care_categories WHERE sort_order = 0 LIMIT 1;
  SELECT id INTO c2 FROM public.primary_care_categories WHERE sort_order = 1 LIMIT 1;
  SELECT id INTO c3 FROM public.primary_care_categories WHERE sort_order = 2 LIMIT 1;
  SELECT id INTO c4 FROM public.primary_care_categories WHERE sort_order = 3 LIMIT 1;
  SELECT id INTO c5 FROM public.primary_care_categories WHERE sort_order = 4 LIMIT 1;
  IF c1 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.primary_care_services WHERE category_id = c1 LIMIT 1) THEN
    INSERT INTO public.primary_care_services (category_id, name, sort_order) VALUES
      (c1, 'Mga Serbisyo para sa Pagsusulong ng Kalusugan', 0),
      (c1, 'Mga Serbisyo para sa Pagsubaybay sa mga Sakit', 1),
      (c1, 'Mga Serbisyo para sa Proteksiyong Pangkalusugan', 2);
  END IF;
  IF c2 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.primary_care_services WHERE category_id = c2 LIMIT 1) THEN
    INSERT INTO public.primary_care_services (category_id, name, sort_order) VALUES
      (c2, 'Konsultasyong Panlabas', 0),
      (c2, 'Mga Serbisyo sa Laboratoryo at Pagsusuri', 1),
      (c2, 'Mga Serbisyo sa Ngipin at Kalusugan ng Bibig', 2),
      (c2, 'Iba Pang Serbisyong Pangkalusugan para sa Indibidwal', 3);
  END IF;
  IF c3 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.primary_care_services WHERE category_id = c3 LIMIT 1) THEN
    INSERT INTO public.primary_care_services (category_id, name, sort_order) VALUES
      (c3, 'Mga Serbisyo sa Pangangalaga Bago Manganak', 0),
      (c3, 'Pangangalaga sa Panganganak at Pagkatapos Manganak', 1),
      (c3, 'Pagsusuri at Pagsubaybay sa Bagong Silang', 2);
  END IF;
  IF c4 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.primary_care_services WHERE category_id = c4 LIMIT 1) THEN
    INSERT INTO public.primary_care_services (category_id, name, sort_order) VALUES
      (c4, 'Pagsusuri sa Nutrisyon at Pagpapayo', 0),
      (c4, 'Mga Programa sa Suplementasyon', 1);
  END IF;
  IF c5 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.primary_care_services WHERE category_id = c5 LIMIT 1) THEN
    INSERT INTO public.primary_care_services (category_id, name, sort_order) VALUES
      (c5, 'Pagbabakuna sa mga Bata', 0),
      (c5, 'Pagbabakuna sa mga Nasa Hustong Gulang at Nakatatanda', 1),
      (c5, 'Pagbabakuna sa mga Espesyal na Kampanya', 2);
  END IF;
END $$;
