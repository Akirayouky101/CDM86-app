#!/bin/bash
# =====================================================
# SETUP AUTOMATICO EMAIL RESEND PER CDM86
# =====================================================

echo "🚀 Configurazione Resend per CDM86..."

# Colori per output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# API Key Resend
RESEND_API_KEY="re_9spPuEQJ_52BQ6qiua7e6qSJSq4uXbsX3"

echo -e "${BLUE}📋 Step 1: Controllo Supabase CLI...${NC}"

# Verifica se Supabase CLI è installato
if ! command -v supabase &> /dev/null; then
    echo -e "${YELLOW}⚠️  Supabase CLI non trovato. Installazione...${NC}"
    npm install -g supabase
else
    echo -e "${GREEN}✅ Supabase CLI già installato${NC}"
fi

echo -e "\n${BLUE}📋 Step 2: Login a Supabase...${NC}"
echo "Per favore completa il login nel browser che si apre"
supabase login

echo -e "\n${BLUE}📋 Step 3: Link al progetto Supabase...${NC}"
echo "Inserisci il PROJECT_REF del tuo progetto Supabase"
echo "(Lo trovi su: Supabase Dashboard → Settings → General → Reference ID)"
read -p "PROJECT_REF: " PROJECT_REF

supabase link --project-ref $PROJECT_REF

echo -e "\n${BLUE}📋 Step 4: Configurazione Secret RESEND_API_KEY...${NC}"
supabase secrets set RESEND_API_KEY=$RESEND_API_KEY

echo -e "\n${BLUE}📋 Step 5: Deploy Edge Function...${NC}"
supabase functions deploy send-organization-email --no-verify-jwt

echo -e "\n${GREEN}✅ Setup completato!${NC}"
echo -e "\n${BLUE}📧 Prossimi passi:${NC}"
echo "1. Vai su Supabase SQL Editor"
echo "2. Esegui il file: database/add_email_notifications.sql"
echo "3. Segnala un'azienda dalla dashboard"
echo "4. Approva dall'admin panel"
echo "5. L'email verrà inviata automaticamente! 🎉"
