-- Aggiungi colonna referred_by_organization_id alla tabella users
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS referred_by_organization_id UUID REFERENCES organizations(id);

-- Crea indice per performance
CREATE INDEX IF NOT EXISTS idx_users_referred_by_organization 
ON users(referred_by_organization_id);

-- Commento per documentazione
COMMENT ON COLUMN users.referred_by_organization_id IS 'ID organizzazione che ha invitato questo utente (se usato codice aziendale)';
