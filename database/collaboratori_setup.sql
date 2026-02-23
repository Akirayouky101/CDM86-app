-- ============================================
-- SISTEMA COLLABORATORI CDM86
-- Pannello: cdm86.org
-- Admin monitoring: cdmottantasei.com
-- ============================================
-- ESEGUIRE IN ORDINE SU SUPABASE SQL EDITOR
-- ============================================

-- ============================================
-- STEP 1: Estendi tabella users per i collaboratori
-- Usiamo UN sistema unico (is_collaborator = true
-- sblocca il 3° livello di compensi)
-- ============================================

ALTER TABLE users
ADD COLUMN IF NOT EXISTS is_collaborator BOOLEAN DEFAULT false;

ALTER TABLE users
ADD COLUMN IF NOT EXISTS collaborator_status VARCHAR(20) DEFAULT NULL
    CHECK (collaborator_status IN ('pending', 'active', 'suspended', 'banned', NULL));

ALTER TABLE users
ADD COLUMN IF NOT EXISTS collaborator_registered_at TIMESTAMP WITH TIME ZONE DEFAULT NULL;

ALTER TABLE users
ADD COLUMN IF NOT EXISTS collaborator_approved_at TIMESTAMP WITH TIME ZONE DEFAULT NULL;

ALTER TABLE users
ADD COLUMN IF NOT EXISTS collaborator_approved_by UUID REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE users
ADD COLUMN IF NOT EXISTS collaborator_notes TEXT DEFAULT NULL; -- note admin (motivo sospensione, ecc.)

ALTER TABLE users
ADD COLUMN IF NOT EXISTS is_organization BOOLEAN DEFAULT false; -- già esistente ma aggiungiamo se manca

COMMENT ON COLUMN users.is_collaborator IS 'True = è un collaboratore (sblocca il 3° livello MLM)';
COMMENT ON COLUMN users.collaborator_status IS 'pending=in attesa approvazione, active=attivo, suspended=sospeso, banned=bannato';
COMMENT ON COLUMN users.collaborator_notes IS 'Note admin: motivo sospensione, ban, ecc.';

-- Indici
CREATE INDEX IF NOT EXISTS idx_users_is_collaborator ON users(is_collaborator);
CREATE INDEX IF NOT EXISTS idx_users_collaborator_status ON users(collaborator_status);

-- ============================================
-- STEP 2: Tabella guadagni collaboratori
-- Record per ogni compenso maturato
-- ============================================

CREATE TABLE IF NOT EXISTS collaborator_earnings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Chi guadagna
    collaborator_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Chi si è iscritto (evento che ha generato il compenso)
    new_user_id UUID REFERENCES users(id) ON DELETE SET NULL,

    -- Livello nella rete del collaboratore (1=diretto, 2=indiretto, 3=terzo livello)
    mlm_level INTEGER NOT NULL CHECK (mlm_level IN (1, 2, 3)),

    -- Chi ha portato l'iscrizione a quel livello
    -- L1: il collaboratore stesso
    -- L2: uno dei suoi L1
    -- L3: uno dei suoi L2
    referrer_at_level UUID REFERENCES users(id) ON DELETE SET NULL,

    -- Tipo di entità iscritta
    registration_type VARCHAR(20) NOT NULL CHECK (registration_type IN ('user', 'azienda', 'associazione')),

    -- Importo base del compenso
    base_amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00,

    -- Eventuale bonus applicato (es. +0.20 per aver superato 100 utenti)
    bonus_amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00,

    -- Totale = base + bonus
    total_amount DECIMAL(10, 2) GENERATED ALWAYS AS (base_amount + bonus_amount) STORED,

    -- Stato pagamento
    status VARCHAR(20) NOT NULL DEFAULT 'credited'
        CHECK (status IN ('credited', 'paid', 'cancelled')),
    -- credited = maturato ma non ancora pagato
    -- paid     = liquidato
    -- cancelled = annullato (es. utente eliminato)

    -- Quando è stato liquidato
    paid_at TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    paid_by UUID REFERENCES users(id) ON DELETE SET NULL, -- admin che ha segnato come pagato

    -- Riferimento al bonus regola applicata (se presente)
    bonus_rule_id UUID DEFAULT NULL, -- FK a collaborator_bonus_rules

    -- Timestamp
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indici
CREATE INDEX IF NOT EXISTS idx_earnings_collaborator ON collaborator_earnings(collaborator_id);
CREATE INDEX IF NOT EXISTS idx_earnings_status ON collaborator_earnings(status);
CREATE INDEX IF NOT EXISTS idx_earnings_created ON collaborator_earnings(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_earnings_new_user ON collaborator_earnings(new_user_id);
CREATE INDEX IF NOT EXISTS idx_earnings_level ON collaborator_earnings(mlm_level);

COMMENT ON TABLE collaborator_earnings IS 'Ogni riga = un compenso maturato dal collaboratore per una iscrizione nella sua rete MLM';

-- ============================================
-- STEP 3: Tabella impostazioni globali collaboratori
-- Soglia pagamento, compensi base, configurabile dall'admin
-- ============================================

CREATE TABLE IF NOT EXISTS collaborator_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Soglia minima per liquidazione (uguale per tutti)
    payout_threshold DECIMAL(10, 2) NOT NULL DEFAULT 50.00,

    -- Compensi L1 (iscrizioni DIRETTE del collaboratore)
    l1_user_amount    DECIMAL(10, 2) NOT NULL DEFAULT 2.00,   -- utente diretto
    l1_azienda_amount DECIMAL(10, 2) NOT NULL DEFAULT 50.00,  -- azienda diretta
    l1_assoc_amount   DECIMAL(10, 2) NOT NULL DEFAULT 0.00,   -- associazione diretta

    -- Compensi L2 (i diretti del collaboratore fanno iscrivere)
    l2_user_amount    DECIMAL(10, 2) NOT NULL DEFAULT 1.00,
    l2_azienda_amount DECIMAL(10, 2) NOT NULL DEFAULT 20.00,
    l2_assoc_amount   DECIMAL(10, 2) NOT NULL DEFAULT 0.00,

    -- Compensi L3 (solo collaboratori — gli indiretti fanno iscrivere)
    l3_user_amount    DECIMAL(10, 2) NOT NULL DEFAULT 0.50,
    l3_azienda_amount DECIMAL(10, 2) NOT NULL DEFAULT 5.00,
    l3_assoc_amount   DECIMAL(10, 2) NOT NULL DEFAULT 0.00,

    -- Singleton: una sola riga di configurazione
    singleton BOOLEAN DEFAULT true UNIQUE CHECK (singleton = true),

    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_by UUID REFERENCES users(id) ON DELETE SET NULL
);

-- Inserisci configurazione default
INSERT INTO collaborator_settings (
    payout_threshold,
    l1_user_amount, l1_azienda_amount, l1_assoc_amount,
    l2_user_amount, l2_azienda_amount, l2_assoc_amount,
    l3_user_amount, l3_azienda_amount, l3_assoc_amount
) VALUES (
    50.00,
    2.00, 50.00, 0.00,
    1.00, 20.00, 0.00,
    0.50,  5.00, 0.00
) ON CONFLICT (singleton) DO NOTHING;

COMMENT ON TABLE collaborator_settings IS 'Configurazione globale compensi e soglia pagamento. Una sola riga (singleton).';

-- ============================================
-- STEP 4: Tabella regole bonus
-- Bonus periodici configurabili dall'admin
-- es. "+€0.20 per ogni utente se superi 100 utenti a giugno"
-- ============================================

CREATE TABLE IF NOT EXISTS collaborator_bonus_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Nome/descrizione del bonus
    name VARCHAR(255) NOT NULL,
    description TEXT,

    -- Periodo di validità
    valid_from DATE NOT NULL,
    valid_to   DATE NOT NULL,

    -- Tipo bonus: per tipo iscrizione
    applies_to VARCHAR(20) NOT NULL DEFAULT 'user'
        CHECK (applies_to IN ('user', 'azienda', 'associazione', 'all')),

    -- Soglia da raggiungere per attivare il bonus
    -- es. "se porti più di 100 utenti in questo periodo"
    threshold_count INTEGER DEFAULT NULL, -- NULL = nessuna soglia (bonus fisso per tutti)
    threshold_type VARCHAR(20) DEFAULT 'user'
        CHECK (threshold_type IN ('user', 'azienda', 'associazione', 'total')),

    -- Importo bonus extra per ogni iscrizione (aggiunto a base_amount)
    bonus_per_registration DECIMAL(10, 2) NOT NULL DEFAULT 0.00,

    -- Attivo/disattivo
    is_active BOOLEAN DEFAULT true,

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Aggiungi FK a collaborator_earnings
ALTER TABLE collaborator_earnings
ADD CONSTRAINT fk_earnings_bonus_rule
FOREIGN KEY (bonus_rule_id) REFERENCES collaborator_bonus_rules(id) ON DELETE SET NULL;

-- Indici
CREATE INDEX IF NOT EXISTS idx_bonus_rules_active ON collaborator_bonus_rules(is_active);
CREATE INDEX IF NOT EXISTS idx_bonus_rules_period ON collaborator_bonus_rules(valid_from, valid_to);

COMMENT ON TABLE collaborator_bonus_rules IS 'Regole bonus periodici. Es: +0.20€/utente se si superano 100 utenti a giugno.';

-- ============================================
-- STEP 5: Vista aggregata guadagni collaboratore
-- Usata dal pannello cdm86.org per mostrare
-- totale maturato, pagato, da saldare
-- ============================================

CREATE OR REPLACE VIEW collaborator_earnings_summary AS
SELECT
    collaborator_id,
    -- Totale maturato (tutto)
    SUM(total_amount) AS total_earned,
    -- Totale già pagato
    SUM(CASE WHEN status = 'paid' THEN total_amount ELSE 0 END) AS total_paid,
    -- Da saldare (credited = maturato ma non pagato)
    SUM(CASE WHEN status = 'credited' THEN total_amount ELSE 0 END) AS total_pending,
    -- Per livello
    SUM(CASE WHEN mlm_level = 1 THEN total_amount ELSE 0 END) AS earned_l1,
    SUM(CASE WHEN mlm_level = 2 THEN total_amount ELSE 0 END) AS earned_l2,
    SUM(CASE WHEN mlm_level = 3 THEN total_amount ELSE 0 END) AS earned_l3,
    -- Contatori iscrizioni
    COUNT(CASE WHEN registration_type = 'user'    AND status != 'cancelled' THEN 1 END) AS users_count,
    COUNT(CASE WHEN registration_type = 'azienda' AND status != 'cancelled' THEN 1 END) AS aziende_count,
    COUNT(CASE WHEN registration_type = 'associazione' AND status != 'cancelled' THEN 1 END) AS assoc_count,
    -- L1 diretto
    COUNT(CASE WHEN mlm_level = 1 AND status != 'cancelled' THEN 1 END) AS direct_count,
    -- Ultimo aggiornamento
    MAX(created_at) AS last_earning_at
FROM collaborator_earnings
GROUP BY collaborator_id;

COMMENT ON VIEW collaborator_earnings_summary IS 'Vista aggregata per dashboard collaboratore: totale maturato, pagato, da saldare.';

-- ============================================
-- STEP 6: Vista admin — tutti i collaboratori
-- Usata da cdmottantasei.com per monitoring
-- ============================================

CREATE OR REPLACE VIEW admin_collaborators_view AS
SELECT
    u.id,
    u.email,
    u.first_name,
    u.last_name,
    u.phone,
    u.referral_code,
    u.is_collaborator,
    u.collaborator_status,
    u.collaborator_registered_at,
    u.collaborator_approved_at,
    u.collaborator_notes,
    u.is_active,
    u.created_at,
    -- Dati guadagni (da summary)
    COALESCE(s.total_earned, 0)   AS total_earned,
    COALESCE(s.total_paid, 0)     AS total_paid,
    COALESCE(s.total_pending, 0)  AS total_pending,
    COALESCE(s.direct_count, 0)   AS direct_count,
    COALESCE(s.users_count, 0)    AS users_count,
    COALESCE(s.aziende_count, 0)  AS aziende_count,
    COALESCE(s.assoc_count, 0)    AS assoc_count,
    -- Notifica: pending da approvare
    CASE WHEN u.collaborator_status = 'pending' THEN true ELSE false END AS needs_approval
FROM users u
LEFT JOIN collaborator_earnings_summary s ON s.collaborator_id = u.id
WHERE u.is_collaborator = true OR u.collaborator_status IS NOT NULL
ORDER BY
    CASE WHEN u.collaborator_status = 'pending' THEN 0 ELSE 1 END,
    u.collaborator_registered_at DESC;

COMMENT ON VIEW admin_collaborators_view IS 'Vista admin per monitorare tutti i collaboratori con i loro guadagni.';

-- ============================================
-- STEP 7: Funzione per calcolare compenso automatico
-- Chiamata ogni volta che un utente/azienda viene approvato
-- ============================================

CREATE OR REPLACE FUNCTION calculate_collaborator_earnings(
    p_new_user_id UUID,
    p_registration_type VARCHAR -- 'user', 'azienda', 'associazione'
)
RETURNS void AS $$
DECLARE
    v_settings collaborator_settings%ROWTYPE;
    v_referrer_l1 UUID;      -- chi ha invitato il nuovo iscritto
    v_referrer_l2 UUID;      -- chi ha invitato il referrer L1
    v_collaborator_l1 UUID;  -- collaboratore a L1 (se il referrer L1 è collab)
    v_collaborator_l2 UUID;  -- collaboratore a L2 (se il referrer L2 è collab)
    v_is_collab_l1 BOOLEAN;
    v_is_collab_l2 BOOLEAN;
    v_referred_by UUID;
    v_l1_amount DECIMAL;
    v_l2_amount DECIMAL;
    v_l3_amount DECIMAL;
    v_bonus_amount DECIMAL;
    v_active_bonus collaborator_bonus_rules%ROWTYPE;
BEGIN
    -- Carica impostazioni compensi
    SELECT * INTO v_settings FROM collaborator_settings LIMIT 1;

    -- Trova chi ha invitato il nuovo utente (L1 rispetto al nuovo iscritto)
    SELECT referred_by_id INTO v_referred_by
    FROM users WHERE id = p_new_user_id;

    IF v_referred_by IS NULL THEN
        RETURN; -- Nessun referrer, nessun compenso
    END IF;

    v_referrer_l1 := v_referred_by;

    -- Determina importi base per tipo iscrizione
    IF p_registration_type = 'user' THEN
        v_l1_amount := v_settings.l1_user_amount;
        v_l2_amount := v_settings.l2_user_amount;
        v_l3_amount := v_settings.l3_user_amount;
    ELSIF p_registration_type = 'azienda' THEN
        v_l1_amount := v_settings.l1_azienda_amount;
        v_l2_amount := v_settings.l2_azienda_amount;
        v_l3_amount := v_settings.l3_azienda_amount;
    ELSIF p_registration_type = 'associazione' THEN
        v_l1_amount := v_settings.l1_assoc_amount;
        v_l2_amount := v_settings.l2_assoc_amount;
        v_l3_amount := v_settings.l3_assoc_amount;
    ELSE
        RETURN;
    END IF;

    -- Cerca bonus attivi per questa data e tipo
    SELECT * INTO v_active_bonus
    FROM collaborator_bonus_rules
    WHERE is_active = true
      AND applies_to IN (p_registration_type, 'all')
      AND valid_from <= CURRENT_DATE
      AND valid_to >= CURRENT_DATE
    ORDER BY bonus_per_registration DESC
    LIMIT 1;

    -- ─── LIVELLO 1 ───────────────────────────────────────────────────────────
    -- Il referrer diretto del nuovo iscritto è un collaboratore?
    SELECT is_collaborator INTO v_is_collab_l1
    FROM users WHERE id = v_referrer_l1;

    IF v_is_collab_l1 = true AND v_l1_amount > 0 THEN
        -- Calcola bonus se applicabile
        v_bonus_amount := 0.00;
        IF v_active_bonus.id IS NOT NULL THEN
            -- Controlla se il collaboratore ha raggiunto la soglia nel periodo
            IF v_active_bonus.threshold_count IS NULL THEN
                v_bonus_amount := v_active_bonus.bonus_per_registration;
            ELSE
                DECLARE
                    v_count INTEGER;
                BEGIN
                    SELECT COUNT(*) INTO v_count
                    FROM collaborator_earnings
                    WHERE collaborator_id = v_referrer_l1
                      AND registration_type = v_active_bonus.threshold_type
                      AND created_at >= v_active_bonus.valid_from
                      AND created_at <= v_active_bonus.valid_to
                      AND status != 'cancelled';
                    IF v_count >= v_active_bonus.threshold_count THEN
                        v_bonus_amount := v_active_bonus.bonus_per_registration;
                    END IF;
                END;
            END IF;
        END IF;

        INSERT INTO collaborator_earnings (
            collaborator_id, new_user_id, mlm_level, referrer_at_level,
            registration_type, base_amount, bonus_amount, status, bonus_rule_id
        ) VALUES (
            v_referrer_l1, p_new_user_id, 1, v_referrer_l1,
            p_registration_type, v_l1_amount, v_bonus_amount, 'credited',
            v_active_bonus.id
        );
    END IF;

    -- ─── LIVELLO 2 ───────────────────────────────────────────────────────────
    -- Chi ha invitato il referrer L1?
    SELECT referred_by_id INTO v_referrer_l2
    FROM users WHERE id = v_referrer_l1;

    IF v_referrer_l2 IS NULL THEN RETURN; END IF;

    SELECT is_collaborator INTO v_is_collab_l2
    FROM users WHERE id = v_referrer_l2;

    IF v_is_collab_l2 = true AND v_l2_amount > 0 THEN
        v_bonus_amount := 0.00;
        IF v_active_bonus.id IS NOT NULL THEN
            IF v_active_bonus.threshold_count IS NULL THEN
                v_bonus_amount := v_active_bonus.bonus_per_registration;
            ELSE
                DECLARE
                    v_count2 INTEGER;
                BEGIN
                    SELECT COUNT(*) INTO v_count2
                    FROM collaborator_earnings
                    WHERE collaborator_id = v_referrer_l2
                      AND registration_type = v_active_bonus.threshold_type
                      AND created_at >= v_active_bonus.valid_from
                      AND created_at <= v_active_bonus.valid_to
                      AND status != 'cancelled';
                    IF v_count2 >= v_active_bonus.threshold_count THEN
                        v_bonus_amount := v_active_bonus.bonus_per_registration;
                    END IF;
                END;
            END IF;
        END IF;

        INSERT INTO collaborator_earnings (
            collaborator_id, new_user_id, mlm_level, referrer_at_level,
            registration_type, base_amount, bonus_amount, status, bonus_rule_id
        ) VALUES (
            v_referrer_l2, p_new_user_id, 2, v_referrer_l1,
            p_registration_type, v_l2_amount, v_bonus_amount, 'credited',
            v_active_bonus.id
        );
    END IF;

    -- ─── LIVELLO 3 (solo collaboratori) ──────────────────────────────────────
    DECLARE
        v_referrer_l3 UUID;
        v_is_collab_l3 BOOLEAN;
    BEGIN
        SELECT referred_by_id INTO v_referrer_l3
        FROM users WHERE id = v_referrer_l2;

        IF v_referrer_l3 IS NULL THEN RETURN; END IF;

        SELECT is_collaborator INTO v_is_collab_l3
        FROM users WHERE id = v_referrer_l3;

        -- Il livello 3 è ESCLUSIVO per i collaboratori
        IF v_is_collab_l3 = true AND v_l3_amount > 0 THEN
            v_bonus_amount := 0.00;
            IF v_active_bonus.id IS NOT NULL THEN
                IF v_active_bonus.threshold_count IS NULL THEN
                    v_bonus_amount := v_active_bonus.bonus_per_registration;
                END IF;
            END IF;

            INSERT INTO collaborator_earnings (
                collaborator_id, new_user_id, mlm_level, referrer_at_level,
                registration_type, base_amount, bonus_amount, status, bonus_rule_id
            ) VALUES (
                v_referrer_l3, p_new_user_id, 3, v_referrer_l2,
                p_registration_type, v_l3_amount, v_bonus_amount, 'credited',
                v_active_bonus.id
            );
        END IF;
    END;

END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION calculate_collaborator_earnings IS
'Calcola e registra i compensi MLM per tutti i collaboratori nella catena referral.
Chiamare questa funzione ogni volta che un utente o azienda viene APPROVATO.
Parametri:
  p_new_user_id: UUID del nuovo iscritto approvato
  p_registration_type: tipo (user / azienda / associazione)';

-- ============================================
-- STEP 8: Trigger auto-aggiornamento updated_at
-- ============================================

CREATE OR REPLACE FUNCTION update_collaborator_earnings_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_earnings_updated ON collaborator_earnings;
CREATE TRIGGER trg_earnings_updated
    BEFORE UPDATE ON collaborator_earnings
    FOR EACH ROW EXECUTE FUNCTION update_collaborator_earnings_timestamp();

-- ============================================
-- STEP 9: RLS (Row Level Security)
-- ============================================

ALTER TABLE collaborator_earnings ENABLE ROW LEVEL SECURITY;
ALTER TABLE collaborator_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE collaborator_bonus_rules ENABLE ROW LEVEL SECURITY;

-- collaborator_earnings: ogni collaboratore vede solo i propri
DROP POLICY IF EXISTS "Collaborator sees own earnings" ON collaborator_earnings;
CREATE POLICY "Collaborator sees own earnings"
ON collaborator_earnings FOR SELECT
USING (
    collaborator_id = auth.uid()
    OR EXISTS (
        SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin'
    )
);

-- Admin può fare tutto su earnings
DROP POLICY IF EXISTS "Admin manages all earnings" ON collaborator_earnings;
CREATE POLICY "Admin manages all earnings"
ON collaborator_earnings FOR ALL
USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
);

-- collaborator_settings: tutti possono leggere, solo admin scrive
DROP POLICY IF EXISTS "Anyone reads settings" ON collaborator_settings;
CREATE POLICY "Anyone reads settings"
ON collaborator_settings FOR SELECT USING (true);

DROP POLICY IF EXISTS "Admin manages settings" ON collaborator_settings;
CREATE POLICY "Admin manages settings"
ON collaborator_settings FOR ALL
USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
);

-- collaborator_bonus_rules: tutti possono leggere, solo admin scrive
DROP POLICY IF EXISTS "Anyone reads bonus rules" ON collaborator_bonus_rules;
CREATE POLICY "Anyone reads bonus rules"
ON collaborator_bonus_rules FOR SELECT USING (true);

DROP POLICY IF EXISTS "Admin manages bonus rules" ON collaborator_bonus_rules;
CREATE POLICY "Admin manages bonus rules"
ON collaborator_bonus_rules FOR ALL
USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
);

-- ============================================
-- STEP 10: Verifica finale
-- ============================================

-- Controlla che tutto sia stato creato correttamente
SELECT
    'collaborator_earnings'  AS tabella, COUNT(*) AS righe FROM collaborator_earnings
UNION ALL SELECT
    'collaborator_settings', COUNT(*) FROM collaborator_settings
UNION ALL SELECT
    'collaborator_bonus_rules', COUNT(*) FROM collaborator_bonus_rules;

-- Controlla colonne aggiunte a users
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'users'
  AND column_name IN (
    'is_collaborator','collaborator_status',
    'collaborator_registered_at','collaborator_approved_at',
    'collaborator_notes'
  )
ORDER BY column_name;

-- Mostra configurazione compensi attiva
SELECT * FROM collaborator_settings;
