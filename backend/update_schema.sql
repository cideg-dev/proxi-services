ALTER TABLE commercant_profiles ADD COLUMN IF NOT EXISTS langues_parlees TEXT[];
ALTER TABLE commercant_profiles ADD COLUMN IF NOT EXISTS assurance_professionnelle BOOLEAN DEFAULT FALSE;