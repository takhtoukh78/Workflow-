# Utiliser l'image Jenkins avec JDK 21
FROM jenkins/jenkins:2.479.2-jdk21

# Passer à l'utilisateur root pour installer des outils supplémentaires
USER root

# Mettre à jour les paquets et installer les dépendances nécessaires
RUN apt-get update && apt-get install -y \
    curl \
    git \
    apt-transport-https \
    ca-certificates \
    software-properties-common \
    build-essential \
    lsb-release \
    libssl-dev \
    openjdk-17-jdk && \
    apt-get clean

# Installer Node.js (via le script officiel NodeSource)
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    node -v && npm -v

# Installer Docker
RUN curl -fsSL https://get.docker.com | sh

# Installer Docker Compose
RUN curl -L "https://github.com/docker/compose/releases/download/2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose

# Assurer l'existence du groupe Docker et ajouter Jenkins à ce groupe
RUN groupadd -f docker && \
    usermod -aG docker jenkins

# Nettoyer les fichiers inutiles pour réduire la taille de l'image
RUN apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/*

# Revenir à l'utilisateur Jenkins
USER jenkins

