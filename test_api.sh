#!/bin/bash
# ==============================================================================
# test_api.sh — Tests automatisés pour l'API carbon-tracker (api.php)
# ==============================================================================
# Usage :
#   1. Lancez d'abord votre app : docker compose up -d
#   2. Adaptez BASE_URL et API_KEY ci-dessous (ou passez-les en variables d'env)
#   3. Rendez le script exécutable : chmod +x test_api.sh
#   4. Lancez : ./test_api.sh
# ==============================================================================

BASE_URL="${BASE_URL:-http://localhost:80}"
API_KEY="${API_KEY:-your-real-api-key-here}"
ENDPOINT="$BASE_URL/php/db_requests.php"

PASS=0
FAIL=0

# Couleurs pour la lisibilité
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# ------------------------------------------------------------------------------
# Fonction utilitaire : compare le code HTTP obtenu à celui attendu
# ------------------------------------------------------------------------------
check_status() {
    local description="$1"
    local expected="$2"
    local actual="$3"

    if [ "$actual" == "$expected" ]; then
        echo -e "${GREEN}[PASS]${NC} $description (HTTP $actual)"
        PASS=$((PASS+1))
    else
        echo -e "${RED}[FAIL]${NC} $description (attendu $expected, obtenu $actual)"
        FAIL=$((FAIL+1))
    fi
}

echo "=============================================="
echo " Tests automatisés — API carbon-tracker"
echo " Cible : $ENDPOINT"
echo "=============================================="
echo ""

# ------------------------------------------------------------------------------
# TEST 1 — Authentification : requête SANS clé API doit être rejetée (401)
# ------------------------------------------------------------------------------
status=$(curl -s -o /dev/null -w "%{http_code}" \
    "$ENDPOINT?request=raw_material")
check_status "Requête sans clé API => 401 attendu" "401" "$status"

# ------------------------------------------------------------------------------
# TEST 2 — Authentification : requête avec une MAUVAISE clé API doit être rejetée (401)
# ------------------------------------------------------------------------------
status=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "X-API-Key: fausse-cle-invalide" \
    "$ENDPOINT?request=raw_material")
check_status "Requête avec clé API invalide => 401 attendu" "401" "$status"

# ------------------------------------------------------------------------------
# TEST 3 — Authentification : requête avec la BONNE clé API doit passer (200)
# ------------------------------------------------------------------------------
status=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "X-API-Key: $API_KEY" \
    "$ENDPOINT?request=raw_material")
check_status "Requête avec clé API valide => 200 attendu" "200" "$status"

# ------------------------------------------------------------------------------
# TEST 4 — Validation : paramètre 'request' manquant doit renvoyer 400
# ------------------------------------------------------------------------------
status=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "X-API-Key: $API_KEY" \
    "$ENDPOINT")
check_status "Sans paramètre 'request' => 400 attendu" "400" "$status"

# ------------------------------------------------------------------------------
# TEST 5 — Validation : valeur de 'request' non whitelistée doit renvoyer 400
# ------------------------------------------------------------------------------
status=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "X-API-Key: $API_KEY" \
    "$ENDPOINT?request=DROP_TABLE_users")
check_status "Requête type non autorisé => 400 attendu" "400" "$status"

# ------------------------------------------------------------------------------
# TEST 6 — Contenu : la réponse 'raw_material' doit être un JSON valide (tableau)
# ------------------------------------------------------------------------------
response=$(curl -s -H "X-API-Key: $API_KEY" "$ENDPOINT?request=raw_material")
if echo "$response" | python3 -c "import sys,json; d=json.load(sys.stdin); assert isinstance(d, list)" 2>/dev/null; then
    echo -e "${GREEN}[PASS]${NC} Réponse 'raw_material' est un tableau JSON valide"
    PASS=$((PASS+1))
else
    echo -e "${RED}[FAIL]${NC} Réponse 'raw_material' n'est pas un JSON valide : $response"
    FAIL=$((FAIL+1))
fi

# ------------------------------------------------------------------------------
# TEST 7 — Injection SQL : tenter une injection dans un paramètre ne doit rien casser
# (les requêtes préparées doivent neutraliser l'attaque, réponse propre attendue)
# ------------------------------------------------------------------------------
status=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "X-API-Key: $API_KEY" \
    --data-urlencode "data={\"material\":[\"a'; DROP TABLE raw_materials; --\"]}" \
    "$ENDPOINT?request=save_steps" -X POST)
# On attend un traitement normal (200) ou une erreur métier propre (400), jamais un 500 (crash serveur)
if [ "$status" == "200" ] || [ "$status" == "400" ]; then
    echo -e "${GREEN}[PASS]${NC} Tentative d'injection SQL neutralisée (HTTP $status, pas de crash 500)"
    PASS=$((PASS+1))
else
    echo -e "${RED}[FAIL]${NC} Tentative d'injection SQL => réponse suspecte (HTTP $status)"
    FAIL=$((FAIL+1))
fi

# ------------------------------------------------------------------------------
# TEST 8 — Payload JSON invalide sur save_steps doit renvoyer 400 (pas de crash)
# ------------------------------------------------------------------------------
status=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "X-API-Key: $API_KEY" \
    --data-urlencode "data=ceci n'est pas du json" \
    "$ENDPOINT?request=save_steps" -X POST)
check_status "JSON invalide sur save_steps => 400 attendu" "400" "$status"

# ------------------------------------------------------------------------------
# TEST 9 — save_steps sans le paramètre 'data' doit renvoyer 400
# ------------------------------------------------------------------------------
status=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "X-API-Key: $API_KEY" \
    "$ENDPOINT?request=save_steps" -X POST)
check_status "save_steps sans 'data' => 400 attendu" "400" "$status"

# ------------------------------------------------------------------------------
# TEST 10 — Vérifier que les erreurs PHP brutes ne fuient pas (pas de stack trace)
# ------------------------------------------------------------------------------
response=$(curl -s -H "X-API-Key: $API_KEY" "$ENDPOINT?request=raw_material")
if echo "$response" | grep -qi "Fatal error\|Warning:\|Stack trace\|on line"; then
    echo -e "${RED}[FAIL]${NC} Fuite d'erreurs PHP détectée dans la réponse !"
    FAIL=$((FAIL+1))
else
    echo -e "${GREEN}[PASS]${NC} Aucune fuite d'erreur PHP brute détectée"
    PASS=$((PASS+1))
fi

# ------------------------------------------------------------------------------
# TEST 11 — Healthcheck : le conteneur doit répondre sur le port exposé
# ------------------------------------------------------------------------------
status=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/")
if [ "$status" != "000" ]; then
    echo -e "${GREEN}[PASS]${NC} Le serveur répond sur $BASE_URL (HTTP $status)"
    PASS=$((PASS+1))
else
    echo -e "${RED}[FAIL]${NC} Le serveur ne répond pas du tout sur $BASE_URL"
    FAIL=$((FAIL+1))
fi

# ------------------------------------------------------------------------------
# Résumé final
# ------------------------------------------------------------------------------
echo ""
echo "=============================================="
echo " Résultat : ${GREEN}$PASS réussis${NC} / ${RED}$FAIL échoués${NC}"
echo "=============================================="

if [ "$FAIL" -gt 0 ]; then
    exit 1
else
    exit 0
fi
