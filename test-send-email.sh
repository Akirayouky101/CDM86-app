#!/bin/bash

# Test manuale Edge Function send-organization-email
# Invia email con la password già salvata

# Ottieni l'organization_id dall'ultimo record
ORG_ID="SOSTITUISCI_CON_ID_ORGANIZATION"

echo "🧪 Testing Edge Function con organization_id: $ORG_ID"
echo ""

curl -X POST \
  'https://uchrjlngfzfibcpdxtky.supabase.co/functions/v1/send-organization-email' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVjaHJqbG5nZnpmaWJjcGR4dGt5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjY1OTQ3MDcsImV4cCI6MjA0MjE3MDcwN30.PHECxLsKbCt3T5l4XVW2xDy6fJ7jB8gxo3mPDt8YgKE' \
  -d "{\"organization_id\": \"$ORG_ID\"}"

echo ""
echo ""
echo "✅ Se vedi 'Email sent successfully', controlla serviziomail1@gmail.com"
