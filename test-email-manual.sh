#!/bin/bash

# Ottieni organization_id dalla console o da Supabase
# Sostituisci fc6e3e35-c25c-4c60-84f7-2346f4a78041 con l'ID reale se diverso

ORG_ID="fc6e3e35-c25c-4c60-84f7-2346f4a78041"

echo "🧪 Testing email invio manuale..."
echo "Organization ID: $ORG_ID"
echo ""

curl -X POST \
  'https://uchrjlngfzfibcpdxtky.supabase.co/functions/v1/send-organization-email' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVjaHJqbG5nZnpmaWJjcGR4dGt5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjY1OTQ3MDcsImV4cCI6MjA0MjE3MDcwN30.PHECxLsKbCt3T5l4XVW2xDy6fJ7jB8gxo3mPDt8YgKE' \
  -d "{\"organization_id\": \"$ORG_ID\"}" \
  --verbose

echo ""
echo ""
echo "✅ Controlla serviziomail1@gmail.com!"
