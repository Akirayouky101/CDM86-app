#!/bin/bash

# ============================================
# CDM86 API Testing Script
# Test tutti gli endpoints principali
# ============================================

echo ""
echo "🧪 ============================================"
echo "   CDM86 Platform - API Testing"
echo "============================================"
echo ""

BASE_URL="http://localhost:3000/api"

# Colori per output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ============================================
# Test 1: Health Check
# ============================================
echo -e "${YELLOW}Test 1: Health Check${NC}"
echo "GET $BASE_URL/health"
curl -s $BASE_URL/health | jq '.'
echo ""
echo ""

# ============================================
# Test 2: Validate Referral Code (ADMIN001)
# ============================================
echo -e "${YELLOW}Test 2: Validate Referral Code${NC}"
echo "POST $BASE_URL/auth/validate-referral"
curl -s -X POST $BASE_URL/auth/validate-referral \
  -H "Content-Type: application/json" \
  -d '{"referralCode": "ADMIN001"}' | jq '.'
echo ""
echo ""

# ============================================
# Test 3: Login con Mario Rossi
# ============================================
echo -e "${YELLOW}Test 3: Login (Mario Rossi)${NC}"
echo "POST $BASE_URL/auth/login"
LOGIN_RESPONSE=$(curl -s -X POST $BASE_URL/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "mario.rossi@test.com",
    "password": "User123!"
  }')

echo $LOGIN_RESPONSE | jq '.'

# Estrai token
TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.data.token')
echo ""
echo -e "${GREEN}✅ Token salvato: ${TOKEN:0:50}...${NC}"
echo ""
echo ""

# ============================================
# Test 4: User Dashboard (con token)
# ============================================
echo -e "${YELLOW}Test 4: User Dashboard${NC}"
echo "GET $BASE_URL/users/dashboard"
curl -s $BASE_URL/users/dashboard \
  -H "Authorization: Bearer $TOKEN" | jq '.'
echo ""
echo ""

# ============================================
# Test 5: My Referral Code
# ============================================
echo -e "${YELLOW}Test 5: My Referral Code${NC}"
echo "GET $BASE_URL/referrals/my-code"
curl -s $BASE_URL/referrals/my-code \
  -H "Authorization: Bearer $TOKEN" | jq '.'
echo ""
echo ""

# ============================================
# Test 6: Referral Stats
# ============================================
echo -e "${YELLOW}Test 6: Referral Stats${NC}"
echo "GET $BASE_URL/referrals/stats"
curl -s $BASE_URL/referrals/stats \
  -H "Authorization: Bearer $TOKEN" | jq '.'
echo ""
echo ""

# ============================================
# Test 7: Lista Persone Invitate
# ============================================
echo -e "${YELLOW}Test 7: Lista Persone Invitate${NC}"
echo "GET $BASE_URL/referrals/invited"
curl -s $BASE_URL/referrals/invited \
  -H "Authorization: Bearer $TOKEN" | jq '.'
echo ""
echo ""

# ============================================
# Test 8: Lista Promozioni (public)
# ============================================
echo -e "${YELLOW}Test 8: Lista Promozioni${NC}"
echo "GET $BASE_URL/promotions"
curl -s "$BASE_URL/promotions?limit=3" | jq '.data[] | {title, partner_name, category}'
echo ""
echo ""

# ============================================
# Test 9: User Points
# ============================================
echo -e "${YELLOW}Test 9: User Points${NC}"
echo "GET $BASE_URL/users/points"
curl -s $BASE_URL/users/points \
  -H "Authorization: Bearer $TOKEN" | jq '.'
echo ""
echo ""

# ============================================
# Test 10: Favorites
# ============================================
echo -e "${YELLOW}Test 10: User Favorites${NC}"
echo "GET $BASE_URL/promotions/user/favorites"
curl -s $BASE_URL/promotions/user/favorites \
  -H "Authorization: Bearer $TOKEN" | jq '.data[] | {title, partner_name}'
echo ""
echo ""

# ============================================
# Summary
# ============================================
echo ""
echo -e "${GREEN}✅ ============================================${NC}"
echo -e "${GREEN}   Test Completati!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo "📝 Credenziali Test:"
echo "   Email: mario.rossi@test.com"
echo "   Password: User123!"
echo "   Referral Code: MARIO001"
echo ""
echo "📚 Documentazione completa: API_DOCUMENTATION.md"
echo ""
