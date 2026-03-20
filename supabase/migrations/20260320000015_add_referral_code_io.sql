-- Migration _0015: add referral_code_io to collaborators
-- referral_code     → link a cdm86.it (piattaforma utenti normali)
-- referral_code_io  → link a cdm86.io (piattaforma collaboratori)

-- 1. Aggiungi la colonna
ALTER TABLE public.collaborators
  ADD COLUMN IF NOT EXISTS referral_code_io TEXT;

-- 2. Genera referral_code_io per i collaboratori esistenti che non ce l'hanno
--    Il codice è: codice esistente + "_IO" oppure 8 caratteri random se il codice è NULL
DO $$
DECLARE
  rec RECORD;
  new_code TEXT;
  attempt INT;
BEGIN
  FOR rec IN
    SELECT id, referral_code FROM public.collaborators WHERE referral_code_io IS NULL
  LOOP
    attempt := 0;
    LOOP
      attempt := attempt + 1;
      IF rec.referral_code IS NOT NULL THEN
        new_code := upper(rec.referral_code) || '_IO';
      ELSE
        new_code := upper(substring(md5(random()::text) from 1 for 8));
      END IF;

      -- Garantisci unicità
      IF NOT EXISTS (
        SELECT 1 FROM public.collaborators WHERE referral_code_io = new_code
      ) THEN
        EXIT;
      END IF;

      -- Fallback dopo 10 tentativi: usa random puro
      IF attempt >= 10 THEN
        new_code := upper(substring(md5(random()::text || clock_timestamp()::text) from 1 for 8));
        EXIT;
      END IF;
    END LOOP;

    UPDATE public.collaborators SET referral_code_io = new_code WHERE id = rec.id;
  END LOOP;
END;
$$;

-- 3. Aggiungi UNIQUE constraint (solo se non esiste già)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'collaborators_referral_code_io_unique'
  ) THEN
    ALTER TABLE public.collaborators
      ADD CONSTRAINT collaborators_referral_code_io_unique UNIQUE (referral_code_io);
  END IF;
END;
$$;

-- 4. Crea una funzione helper per generare referral_code_io unico dato un referral_code base
CREATE OR REPLACE FUNCTION public.generate_referral_code_io(p_base_code TEXT DEFAULT NULL)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
  new_code TEXT;
  attempt INT := 0;
BEGIN
  LOOP
    attempt := attempt + 1;
    IF p_base_code IS NOT NULL AND attempt <= 5 THEN
      new_code := upper(trim(p_base_code)) || '_IO';
    ELSE
      new_code := upper(substring(md5(random()::text || clock_timestamp()::text) from 1 for 6)) || 'IO';
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM public.collaborators WHERE referral_code_io = new_code
    ) THEN
      RETURN new_code;
    END IF;

    IF attempt >= 20 THEN
      RETURN upper(substring(md5(random()::text || now()::text) from 1 for 8));
    END IF;
  END LOOP;
END;
$$;
