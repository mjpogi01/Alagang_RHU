-- =============================================================================
-- Alagang RHU – Official primary care services list (seed).
-- Run after 008. Replaces existing categories and services with the official list.
-- Five categories: Population-Based, Individual-Based, Maternal and Newborn, Nutrition, Vaccination (1–17).
-- Admin can still add, edit, archive, or delete categories and services after this.
-- =============================================================================

-- Clear existing data so we can insert the official list
DELETE FROM public.primary_care_services;
DELETE FROM public.primary_care_categories;

DO $$
DECLARE
  c_pop  uuid;
  c_ind  uuid;
  c_mat  uuid;
  c_nut  uuid;
  c_vac  uuid;
BEGIN
  -- 1. POPULATION-BASED SERVICES (orange/coral, group icon)
  INSERT INTO public.primary_care_categories (id, title, color_hex, icon_name, sort_order)
  VALUES (gen_random_uuid(), 'POPULATION-BASED SERVICES', 'FFCCBC', 'group_outlined', 0)
  RETURNING id INTO c_pop;

  INSERT INTO public.primary_care_services (category_id, name, sort_order) VALUES
    (c_pop, 'Health Education and Awareness Activities', 0),
    (c_pop, 'Pagtuklas ng mga Nakakahawang Sakit sa Komunidad', 1),
    (c_pop, 'Pagpapatupad ng mga Kaukulang Interbensyon at Kontrol', 2),
    (c_pop, 'Mga Babala at Impormasyon sa mga Laganap na Sakit', 3),
    (c_pop, 'Kampanya Kontra Dengue', 4),
    (c_pop, 'Food Safety Training / Ligtas na Paghahanda ng Pagkain', 5);

  -- 2. INDIVIDUAL-BASED SERVICES (blue, monitor_heart icon)
  INSERT INTO public.primary_care_categories (id, title, color_hex, icon_name, sort_order)
  VALUES (gen_random_uuid(), 'INDIVIDUAL-BASED SERVICES', 'FFBBDEFB', 'monitor_heart_outlined', 1)
  RETURNING id INTO c_ind;

  INSERT INTO public.primary_care_services (category_id, name, sort_order) VALUES
    (c_ind, 'Medical Consultation', 0),
    (c_ind, 'Physical Examination', 1),
    (c_ind, 'Complete Blood Count with Platelet Count - ₱150.00', 2),
    (c_ind, 'Urinalysis - ₱100.00', 3),
    (c_ind, 'Fasting Blood Sugar - ₱100.00', 4),
    (c_ind, 'Sputum Microscopy - NO FEE INDICATED', 5),
    (c_ind, 'Creatinine - ₱100.00', 6),
    (c_ind, 'Dengue Rapid Test - ₱700.00 (Dengue Duo)', 7),
    (c_ind, 'Pamimigay ng mga Pangunahing Gamot', 8),
    (c_ind, 'Libreng Gamot at Bakuna', 9),
    (c_ind, 'COVID-19', 10),
    (c_ind, 'Influenza', 11),
    (c_ind, 'Tetanus, Diphtheria, Pertussis (Tdap / Td)', 12),
    (c_ind, 'Measles, Mumps, Rubella (MMR)', 13),
    (c_ind, 'Varicella', 14),
    (c_ind, 'Human Papillomavirus (HPV)', 15),
    (c_ind, 'Pneumococcal (PCV15, PCV20, PCV21, PPSV23)', 16),
    (c_ind, 'Hepatitis B', 17),
    (c_ind, 'Inactivated Poliovirus (IPV)', 18),
    (c_ind, 'Tetanus Toxoid', 19),
    (c_ind, 'Family Planning Counseling', 20),
    (c_ind, 'Contraceptive Services', 21),
    (c_ind, 'Oral and Dental Health Check-Up', 22),
    (c_ind, 'Dental extraction - ₱250.00 per tooth', 23),
    (c_ind, 'Nutritional Status Assessment', 24),
    (c_ind, 'Nutrition Counseling', 25),
    (c_ind, 'Pagtahi ng Mababaw na Sugat - ₱100.00', 26),
    (c_ind, 'Paglilinis ng Sugat - ₱100.00', 27),
    (c_ind, 'Ambulance Service', 28);

  -- 3. MATERNAL AND NEWBORN CARE SERVICES (pink, favorite icon)
  INSERT INTO public.primary_care_categories (id, title, color_hex, icon_name, sort_order)
  VALUES (gen_random_uuid(), 'MATERNAL AND NEWBORN CARE SERVICES', 'FFF8BBD0', 'favorite_border', 2)
  RETURNING id INTO c_mat;

  INSERT INTO public.primary_care_services (category_id, name, sort_order) VALUES
    (c_mat, 'Medical Interview (History Tracking)', 0),
    (c_mat, 'Medical Check-Up (Physical Examination)', 1),
    (c_mat, 'Screening', 2),
    (c_mat, 'Pagbabakuna', 3),
    (c_mat, 'Micronutrient Supplementation', 4),
    (c_mat, 'Birth Plan Preparation', 5),
    (c_mat, 'Breastfeeding Counseling', 6),
    (c_mat, 'Breastfeeding Support', 7),
    (c_mat, 'Health Counseling at Health Promotion', 8),
    (c_mat, 'Tetanus (TT / Td)', 9),
    (c_mat, 'Influenza', 10),
    (c_mat, 'COVID-19', 11),
    (c_mat, 'BCG', 12),
    (c_mat, 'Hepatitis B (Birth Dose)', 13),
    (c_mat, 'Pentavalent Vaccine (DPT-HepB-Hib)', 14),
    (c_mat, 'Oral Polio Vaccine (OPV)', 15),
    (c_mat, 'Inactivated Polio Vaccine (IPV)', 16),
    (c_mat, 'Pneumococcal Conjugate Vaccine (PCV)', 17),
    (c_mat, 'Measles, Mumps, Rubella (MMR)', 18);

  -- 4. NUTRITION SERVICES (yellow, timelapse icon)
  INSERT INTO public.primary_care_categories (id, title, color_hex, icon_name, sort_order)
  VALUES (gen_random_uuid(), 'NUTRITION SERVICES', 'FFFFF59D', 'timelapse_outlined', 3)
  RETURNING id INTO c_nut;

  INSERT INTO public.primary_care_services (category_id, name, sort_order) VALUES
    (c_nut, 'Pagbibigay ng Payo Ukol sa Tamang Nutrisyon', 0),
    (c_nut, 'Micronutrient Supplementation', 1),
    (c_nut, 'Pamamahala sa Malnutrisyon', 2);

  -- 5. VACCINATION SERVICES (Edad 1–17 Taong Gulang) (teal, vaccines icon)
  INSERT INTO public.primary_care_categories (id, title, color_hex, icon_name, sort_order)
  VALUES (gen_random_uuid(), 'VACCINATION SERVICES (Edad 1–17 Taong Gulang)', 'FFB2DFDB', 'vaccines_outlined', 4)
  RETURNING id INTO c_vac;

  INSERT INTO public.primary_care_services (category_id, name, sort_order) VALUES
    (c_vac, 'Tetanus and Diphtheria Toxoid (Td)', 0),
    (c_vac, 'Measles at Rubella (Tigdas / Tigdás Hangin)', 1),
    (c_vac, 'Human Papillomavirus (HPV)', 2);

END $$;
