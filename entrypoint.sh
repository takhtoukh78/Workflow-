#!/bin/sh
echo "✅ entrypoint.sh exécuté !"

# Vérifier que `curl` et `jq` sont installés
if ! command -v curl >/dev/null 2>&1; then
    echo "📦 Installation de curl..."
    apk add --no-cache curl 2>/dev/null || apt-get update && apt-get install -y curl 2>/dev/null
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "📦 Installation de jq..."
    apk add --no-cache jq 2>/dev/null || apt-get update && apt-get install -y jq 2>/dev/null
fi

# Vérifier la connexion à Vault avant d'aller plus loin
echo "⏳ Attente de Vault..."
until curl -s -o /dev/null -w "%{http_code}" -H "X-Vault-Token: $VAULT_TOKEN" -X GET "$VAULT_ADDR/v1/sys/health" | grep -q "200"; do
    echo "🔄 Vault pas encore prêt, re-essai dans 2s..."
    sleep 2
done

echo "✅ Vault est prêt !"

# Récupérer les secrets depuis Vault
echo "🔐 Récupération des secrets..."
VAULT_RESPONSE=$(curl -s -H "X-Vault-Token: $VAULT_TOKEN" -X GET "$VAULT_ADDR/v1/secret/data/dev/application" | jq .data.data)

export SPRING_DATASOURCE_USERNAME=$(echo "$VAULT_RESPONSE" | jq -r '.["spring.datasource.username"] // "default-db-user"')
export SPRING_DATASOURCE_URL=$(echo "$VAULT_RESPONSE" | jq -r '.["spring.datasource.url"] // "default-db-user"')
export SPRING_DATASOURCE_PASSWORD=$(echo "$VAULT_RESPONSE" | jq -r '.["spring.datasource.password"] // "default-db-password"')
export SPRING_SECURITY_USER_NAME=$(echo "$VAULT_RESPONSE" | jq -r '.["spring.security.user.name"] // "admin"')
export SPRING_SECURITY_USER_PASSWORD=$(echo "$VAULT_RESPONSE" | jq -r '.["spring.security.user.password"] // "admin123"')
export SPRING_SECURITY_OAUTH2_CLIENT_REGISTRATION_GOOGLE_CLIENT_ID=$(echo "$VAULT_RESPONSE" | jq -r '.["spring.security.oauth2.client.registration.google.client-id"] // "default-client-id"')
export SPRING_SECURITY_OAUTH2_CLIENT_REGISTRATION_GOOGLE_CLIENT_SECRET=$(echo "$VAULT_RESPONSE" | jq -r '.["spring.security.oauth2.client.registration.google.client-secret"] // "default-client-secret"')
export JWT_SECRET=$(echo "$VAULT_RESPONSE" | jq -r '.["jwt.secret"] // "default-jwt-secret"')
export JWT_EXPIRATION=$(echo "$VAULT_RESPONSE" | jq -r '.["jwt.expiration"] // "3600"')

# Afficher les variables récupérées pour debug (ne pas faire en prod)
echo "🔍 SPRING_DATASOURCE_USERNAME = $SPRING_DATASOURCE_USERNAME"
echo "🔍 SPRING_SECURITY_USER_NAME = $SPRING_SECURITY_USER_NAME"
echo "🔍 JWT_EXPIRATION = $JWT_EXPIRATION"

# Lancer l'application
exec java -jar app.jar
