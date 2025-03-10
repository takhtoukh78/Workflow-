#!/bin/sh
set -e  # Arrêter le script en cas d'erreur

echo "✅ entrypoint.sh exécuté !"

# Vérifier que `curl` et `jq` sont installés
if ! command -v curl >/dev/null 2>&1; then
    echo "📦 Installation de curl..."
    if command -v apk >/dev/null 2>&1; then
        apk add --no-cache curl
    elif command -v apt-get >/dev/null 2>&1; then
        apt-get update && apt-get install -y curl
    else
        echo "❌ Impossible d'installer curl (ni apk ni apt-get trouvés) !"
        exit 1
    fi
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "📦 Installation de jq..."
    if command -v apk >/dev/null 2>&1; then
        apk add --no-cache jq
    elif command -v apt-get >/dev/null 2>&1; then
        apt-get update && apt-get install -y jq
    else
        echo "❌ Impossible d'installer jq (ni apk ni apt-get trouvés) !"
        exit 1
    fi
fi

# Vérifier la connexion à Vault avant d'aller plus loin
echo "⏳ Attente de Vault..."
until [ "$(curl -s -o /dev/null -w "%{http_code}" -H "X-Vault-Token: $VAULT_TOKEN" -X GET "$VAULT_ADDR/v1/sys/health")" = "200" ]; do
    echo "🔄 Vault pas encore prêt, ré-essai dans 2s..."
    sleep 2
done

echo "✅ Vault est prêt !"

# Récupérer les secrets depuis Vault
echo "🔐 Récupération des secrets depuis $VAULT_ADDR/v1/secret/data/dev/application ..."
VAULT_RESPONSE=$(curl -s -H "X-Vault-Token: $VAULT_TOKEN" -X GET "$VAULT_ADDR/v1/secret/data/dev/application" | jq .data.data)

########################################
# Export des variables d'environnement #
########################################

# Environnement de l'application
export APP_ENVIRONMENT=$(echo "$VAULT_RESPONSE" | jq -r '.["app.environment"] // "dev"')

# JWT
export JWT_EXPIRATION=$(echo "$VAULT_RESPONSE" | jq -r '.["jwt.expiration"] // "86400000"')
export JWT_SECRET=$(echo "$VAULT_RESPONSE" | jq -r '.["jwt.secret"] // "default-jwt-secret"')

# Server / Spring
export SERVER_FORWARD_HEADERS_STRATEGY=$(echo "$VAULT_RESPONSE" | jq -r '.["server.forward-headers-strategy"] // "framework"')
export SPRING_APPLICATION_NAME=$(echo "$VAULT_RESPONSE" | jq -r '.["spring.application.name"] // "the-tip-top"')
export SPRING_DATASOURCE_PASSWORD=$(echo "$VAULT_RESPONSE" | jq -r '.["spring.datasource.password"] // "dev_password"')
export SPRING_DATASOURCE_URL=$(echo "$VAULT_RESPONSE" | jq -r '.["spring.datasource.url"] // "jdbc:postgresql://localhost:5432/default-db"' )
export SPRING_DATASOURCE_USERNAME=$(echo "$VAULT_RESPONSE" | jq -r '.["spring.datasource.username"] // "admin_dev"' )
export SPRING_JPA_DATABASE_PLATFORM=$(echo "$VAULT_RESPONSE" | jq -r '.["spring.jpa.database-platform"] // "org.hibernate.dialect.PostgreSQLDialect"')
export SPRING_JPA_HIBERNATE_DDL_AUTO=$(echo "$VAULT_RESPONSE" | jq -r '.["spring.jpa.hibernate.ddl-auto"] // "update"')
export SPRING_JPA_SHOW_SQL=$(echo "$VAULT_RESPONSE" | jq -r '.["spring.jpa.show-sql"] // "true"')
export SPRING_SECURITY_USER_NAME=$(echo "$VAULT_RESPONSE" | jq -r '.["spring.security.user.name"] // "admin"')
export SPRING_SECURITY_USER_PASSWORD=$(echo "$VAULT_RESPONSE" | jq -r '.["spring.security.user.password"] // "admin123"')
export SPRINGDOC_API_DOCS_ENABLED=$(echo "$VAULT_RESPONSE" | jq -r '.["springdoc.api-docs.enabled"] // "true"')
export SPRINGDOC_SWAGGER_UI_PATH=$(echo "$VAULT_RESPONSE" | jq -r '.["springdoc.swagger-ui.path"] // "/swagger-ui.html"')
export SERVER_PORT=$(echo "$VAULT_RESPONSE" | jq -r '.["server.port"] // "8087"')

#####################
# OAuth2 - Google   #
#####################
export SPRING_SECURITY_OAUTH2_CLIENT_REGISTRATION_GOOGLE_CLIENT_ID=$(echo "$VAULT_RESPONSE" | jq -r '.["spring.security.oauth2.client.registration.google.client-id"] // "default-google-client-id"')
export SPRING_SECURITY_OAUTH2_CLIENT_REGISTRATION_GOOGLE_CLIENT_SECRET=$(echo "$VAULT_RESPONSE" | jq -r '.["spring.security.oauth2.client.registration.google.client-secret"] // "default-google-client-secret"')

#####################
# OAuth2 - Facebook #
#####################
export SPRING_SECURITY_OAUTH2_CLIENT_REGISTRATION_FACEBOOK_CLIENT_ID=$(echo "$VAULT_RESPONSE" | jq -r '.["spring.security.oauth2.client.registration.facebook.client-id"] // "default-facebook-client-id"')
export SPRING_SECURITY_OAUTH2_CLIENT_REGISTRATION_FACEBOOK_CLIENT_SECRET=$(echo "$VAULT_RESPONSE" | jq -r '.["spring.security.oauth2.client.registration.facebook.client-secret"] // "default-facebook-client-secret"')
export SPRING_SECURITY_OAUTH2_CLIENT_REGISTRATION_FACEBOOK_REDIRECT_URI=$(echo "$VAULT_RESPONSE" | jq -r '.["spring.security.oauth2.client.registration.facebook.redirect-uri"] // "https://dev-back.the-tip-top.site/login/oauth2/code/facebook"')
export SPRING_SECURITY_OAUTH2_CLIENT_REGISTRATION_FACEBOOK_SCOPE=$(echo "$VAULT_RESPONSE" | jq -r '.["spring.security.oauth2.client.registration.facebook.scope"] // "email,public_profile"')

export SPRING_SECURITY_OAUTH2_CLIENT_PROVIDER_FACEBOOK_AUTHORIZATION_URI=$(echo "$VAULT_RESPONSE" | jq -r '.["spring.security.oauth2.client.provider.facebook.authorization-uri"] // "https://www.facebook.com/v17.0/dialog/oauth"')
export SPRING_SECURITY_OAUTH2_CLIENT_PROVIDER_FACEBOOK_TOKEN_URI=$(echo "$VAULT_RESPONSE" | jq -r '.["spring.security.oauth2.client.provider.facebook.token-uri"] // "https://graph.facebook.com/v17.0/oauth/access_token"')
export SPRING_SECURITY_OAUTH2_CLIENT_PROVIDER_FACEBOOK_USER_INFO_URI=$(echo "$VAULT_RESPONSE" | jq -r '.["spring.security.oauth2.client.provider.facebook.user-info-uri"] // "https://graph.facebook.com/me?fields=id,name,email"')
export SPRING_SECURITY_OAUTH2_CLIENT_PROVIDER_FACEBOOK_USER_NAME_ATTRIBUTE=$(echo "$VAULT_RESPONSE" | jq -r '.["spring.security.oauth2.client.provider.facebook.user-name-attribute"] // "id"')

##################################
# Affichage de quelques variables
##################################
echo "🔍 APP_ENVIRONMENT        = $APP_ENVIRONMENT"
echo "🔍 SERVER_PORT            = $SERVER_PORT"
echo "🔍 SPRING_APPLICATION_NAME= $SPRING_APPLICATION_NAME"
echo "🔍 SPRING_DATASOURCE_URL  = $SPRING_DATASOURCE_URL"
echo "🔍 SPRING_SECURITY_USER   = $SPRING_SECURITY_USER_NAME"
echo "🔍 JWT_EXPIRATION         = $JWT_EXPIRATION"

echo "✅ Lancement de l'application Java..."

# Lancer l'application Java
exec java -jar app.jar
