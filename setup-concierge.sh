#!/bin/bash

# Configuration
APP_NAME="concierge-app"
PHP_VERSION="8.3"

# Formatting helpers
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export NC='\033[0m' # No Color

function log_success() { echo -e "${GREEN}✔ $1${NC}"; }
function log_error() { echo -e "${RED}✘ ERROR: $1${NC}"; exit 1; }

echo "🚀 Starting robust setup for $APP_NAME..."

# 1. Check if we are in WSL
if [[ ! -f /proc/sys/fs/binfmt_misc/WSLInterop && ! -f /run/WSL ]]; then
    log_error "This script is designed for WSL2. Please run inside a WSL terminal."
fi

# 2. Validate Docker is running and native
if ! docker info > /dev/null 2>&1; then
    log_error "Docker is not running. Try 'sudo service docker start'."
fi

if docker version | grep -iq "docker desktop"; then
    echo "⚠️  Warning: Docker Desktop detected. Native Engine is preferred for this workflow."
fi

# 3. Create project directory if it doesn't exist
if [ -d "$APP_NAME" ]; then
    echo "📂 Directory $APP_NAME already exists. Entering directory..."
    cd "$APP_NAME" || log_error "Failed to enter directory."
else
    echo "🏗️  Creating fresh Laravel 11 project..."
    curl -s "https://laravel.build/$APP_NAME?with=mysql,redis" | bash || log_error "Laravel installation failed."
    cd "$APP_NAME" || log_error "Failed to enter new project directory."
fi

# 4. Start Sail (Docker containers)
echo "🚦 Starting Docker containers..."
./vendor/bin/sail up -d || log_error "Sail failed to start. Check if port 80 or 3306 is already in use."

# 5. Wait for MySQL to be ready
echo "⏳ Waiting for MySQL to initialize..."
MAX_TRIES=30
COUNT=0
until ./vendor/bin/sail artisan db:monitor --databases=mysql > /dev/null 2>&1 || [ $COUNT -eq $MAX_TRIES ]; do
    sleep 2
    ((COUNT++))
    echo -n "."
done

if [ $COUNT -eq $MAX_TRIES ]; then
    log_error "MySQL did not become ready in time."
fi
echo ""

# 6. Database Migrations
echo "📦 Running database migrations..."
./vendor/bin/sail artisan migrate --force || log_error "Database migration failed."

# 7. Filament Installation
if ! grep -q "filament/filament" composer.json; then
    echo "🛠️  Installing Filament..."
    ./vendor/bin/sail composer require filament/filament:"^3.2" -W || log_error "Filament composer installation failed."
    ./vendor/bin/sail artisan filament:install --panels || log_error "Filament panel installation failed."
else
    log_success "Filament is already installed."
fi

# 8. Setup Alias (Persistent)
if ! grep -q "alias sail=" ~/.bashrc; then
    echo "Adding 'sail' alias to ~/.bashrc..."
    echo "alias sail='[ -f sail ] && sh sail || sh vendor/bin/sail'" >> ~/.bashrc
    log_success "Alias added. Please run 'source ~/.bashrc' after script finish."
fi

echo "----------------------------------------------------"
log_success "SETUP COMPLETE FOR $APP_NAME"
echo -e "Next steps:"
echo -e "1. Run: ${GREEN}source ~/.bashrc${NC}"
echo -e "2. Run: ${GREEN}sail artisan make:filament-user${NC} (To create your admin account)"
echo -e "3. Visit: ${GREEN}http://localhost/admin${NC}"
echo "----------------------------------------------------"

