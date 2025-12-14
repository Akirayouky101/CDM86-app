#!/bin/bash

# ============================================
# SCRIPT PER ANALIZZARE DATABASE SUPABASE
# ============================================

echo "🔍 ANALISI COMPLETA DATABASE SUPABASE CDM86"
echo "==========================================="
echo ""

# Colori per output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Supabase credentials
SUPABASE_URL="https://uchrjlngfzfibcpdxtky.supabase.co"
SUPABASE_SERVICE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVjaHJqbG5nZnpmaWJjcGR4dGt5Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDAzMTIwNiwiZXhwIjoyMDc1NjA3MjA2fQ.w3U0GrS0yfhCkZXMTR-vO93RMCXNFV8CqjXlT_xd4Z0"

# Funzione per eseguire query SQL
run_query() {
    local title="$1"
    local query="$2"
    
    echo -e "${YELLOW}=== $title ===${NC}"
    
    curl -X POST \
        "${SUPABASE_URL}/rest/v1/rpc/execute_sql" \
        -H "apikey: ${SUPABASE_SERVICE_KEY}" \
        -H "Authorization: Bearer ${SUPABASE_SERVICE_KEY}" \
        -H "Content-Type: application/json" \
        -d "{\"query\": \"${query}\"}" 2>/dev/null | jq .
    
    echo ""
}

# 1. Lista tabelle
echo -e "${GREEN}📋 1. LISTA TABELLE${NC}"
psql "$DATABASE_URL" -c "
SELECT tablename 
FROM pg_tables 
WHERE schemaname = 'public' 
ORDER BY tablename;
" 2>/dev/null || echo "⚠️  Usa il file ANALYZE_DATABASE.sql nel SQL Editor di Supabase"

echo ""
echo "================================================================"
echo "🎯 ISTRUZIONI PER L'ANALISI COMPLETA:"
echo "================================================================"
echo ""
echo "1. Vai su Supabase Dashboard: https://supabase.com/dashboard"
echo "2. Seleziona il progetto CDM86 (uchrjlngfzfibcpdxtky)"
echo "3. Vai su 'SQL Editor' nel menu laterale"
echo "4. Apri il file ANALYZE_DATABASE.sql"
echo "5. Copia e incolla le query una alla volta"
echo "6. Esegui ogni query e copia i risultati"
echo ""
echo "================================================================"
echo "📊 QUERY PRINCIPALI DA ESEGUIRE:"
echo "================================================================"
echo ""
echo "✅ Query 1-7: Struttura database (tabelle, colonne, relazioni, RLS)"
echo "✅ Query 8: Conteggio record per tabella"
echo "✅ Query 9-11: Sample data (users, promotions, organizations)"
echo "✅ Query 12-14: Verifica sistema referral e statistiche"
echo "✅ Query 15: Verifica sync auth.users ↔ public.users"
echo ""
echo "================================================================"
echo ""

# Se hai access diretto al DB, puoi usare questo:
if [ ! -z "$DATABASE_URL" ]; then
    echo -e "${GREEN}✅ DATABASE_URL trovato! Eseguo analisi...${NC}"
    echo ""
    
    # Esegui tutte le query dal file
    psql "$DATABASE_URL" -f ANALYZE_DATABASE.sql
else
    echo -e "${RED}⚠️  DATABASE_URL non impostato${NC}"
    echo ""
    echo "Per connessione diretta PostgreSQL:"
    echo "export DATABASE_URL='postgresql://postgres:[PASSWORD]@db.uchrjlngfzfibcpdxtky.supabase.co:5432/postgres'"
    echo ""
    echo "Oppure usa il SQL Editor su Supabase Dashboard (metodo consigliato)"
fi

echo ""
echo "================================================================"
echo "📝 RISULTATI DA CONDIVIDERE:"
echo "================================================================"
echo ""
echo "Dopo aver eseguito le query, inviami:"
echo ""
echo "1️⃣  Lista completa delle TABELLE (Query 1)"
echo "2️⃣  Struttura USERS table (Query 2 filtrata per users)"
echo "3️⃣  Tutte le FOREIGN KEYS (Query 3)"
echo "4️⃣  RLS POLICIES attive (Query 5)"
echo "5️⃣  TRIGGERS (Query 6)"
echo "6️⃣  Conteggio record (Query 8)"
echo "7️⃣  Sample users e referral status (Query 9, 12)"
echo "8️⃣  Eventuali errori di integrità (Query 13, 15)"
echo ""
echo "================================================================"
