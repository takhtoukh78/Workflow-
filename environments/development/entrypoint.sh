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


# Export des variables d'environnement pour Spring Boot
export SPRING_APPLICATION_NAME=$(echo "$VAULT_RESPONSE" | jq -r '.["spring.application.name"] // "the-tip-top"')
export SPRING_DATASOURCE_USERNAME=$(echo "$VAULT_RESPONSE" | jq -r '.["spring.datasource.username"] // "default-db-user"')
export SPRING_DATASOURCE_URL=$(echo "$VAULT_RESPONSE" | jq -r '.["spring.datasource.url"] // "jdbc:postgresql://localhost:5432/default-db"')
export SPRING_DATASOURCE_PASSWORD=$(echo "$VAULT_RESPONSE" | jq -r '.["spring.datasource.password"] // "default-db-password"')

# Sécurité Spring (utilisateur de base)
export SPRING_SECURITY_USER_NAME=$(echo "$VAULT_RESPONSE" | jq -r '.["spring.security.user.name"] // "admin"')
export SPRING_SECURITY_USER_PASSWORD=$(echo "$VAULT_RESPONSE" | jq -r '.["spring.security.user.password"] // "admin123"')

# OAuth2 - Google
export SPRING_SECURITY_OAUTH2_CLIENT_REGISTRATION_GOOGLE_CLIENT_ID=$(echo "$VAULT_RESPONSE" | jq -r '.["spring.security.oauth2.client.registration.google.client-id"] // "default-google-client-id"')
export SPRING_SECURITY_OAUTH2_CLIENT_REGISTRATION_GOOGLE_CLIENT_SECRET=$(echo "$VAULT_RESPONSE" | jq -r '.["spring.security.oauth2.client.registration.google.client-secret"] // "default-google-client-secret"')

# OAuth2 - Facebook
export SPRING_SECURITY_OAUTH2_CLIENT_REGISTRATION_FACEBOOK_CLIENT_ID=$(echo "$VAULT_RESPONSE" | jq -r '.["spring.security.oauth2.client.registration.facebook.client-id"] // "default-facebook-client-id"')
export SPRING_SECURITY_OAUTH2_CLIENT_REGISTRATION_FACEBOOK_CLIENT_SECRET=$(echo "$VAULT_RESPONSE" | jq -r '.["spring.security.oauth2.client.registration.facebook.client-secret"] // "default-facebook-client-secret"')
export SPRING_SECURITY_OAUTH2_CLIENT_REGISTRATION_FACEBOOK_REDIRECT_URI=$(echo "$VAULT_RESPONSE" | jq -r '.["spring.security.oauth2.client.registration.facebook.redirect-uri"] // "{baseUrl}/login/oauth2/code/facebook"')
export SPRING_SECURITY_OAUTH2_CLIENT_REGISTRATION_FACEBOOK_SCOPE=$(echo "$VAULT_RESPONSE" | jq -r '.["spring.security.oauth2.client.registration.facebook.scope"] // "email,public_profile"')

# JWT
export JWT_SECRET=$(echo "$VAULT_RESPONSE" | jq -r '.["jwt.secret"] // "default-jwt-secret"')
export JWT_EXPIRATION=$(echo "$VAULT_RESPONSE" | jq -r '.["jwt.expiration"] // "3600"')

# SpringDoc & Swagger
export SPRINGDOC_API_DOCS_ENABLED=$(echo "$VAULT_RESPONSE" | jq -r '.["springdoc.api-docs.enabled"] // "true"')
export SPRINGDOC_SWAGGER_UI_PATH=$(echo "$VAULT_RESPONSE" | jq -r '.["springdoc.swagger-ui.path"] // "/swagger-ui.html"')

# Logs et debug
export SPRING_JPA_SHOW_SQL=$(echo "$VAULT_RESPONSE" | jq -r '.["spring.jpa.show-sql"] // "false"')
export SPRING_JPA_DATABASE_PLATFORM=$(echo "$VAULT_RESPONSE" | jq -r '.["spring.jpa.database-platform"] // "org.hibernate.dialect.PostgreSQLDialect"')
export SPRING_JPA_HIBERNATE_DDL_AUTO=$(echo "$VAULT_RESPONSE" | jq -r '.["spring.jpa.hibernate.ddl-auto"] // "update"')

# Headers Forwarding
export SERVER_FORWARD_HEADERS_STRATEGY=$(echo "$VAULT_RESPONSE" | jq -r '.["server.forward-headers-strategy"] // "framework"')

# Afficher les variables récupérées pour debug (ne pas faire en prod)
echo "🔍 SPRING_DATASOURCE_USERNAME = $SPRING_DATASOURCE_USERNAME"
echo "🔍 SPRING_SECURITY_USER_NAME = $SPRING_SECURITY_USER_NAME"
echo "🔍 JWT_EXPIRATION = $JWT_EXPIRATION"

# Lancer l'application
exec java -jar app.jar
