#!/bin/bash

# Cloudflare Pages Deployment Helper Script
# This script helps you deploy to Cloudflare Pages locally for testing

set -e

echo "🚀 Takwa Cloudflare Pages Deployment"
echo "====================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to check if Wrangler is installed
check_wrangler() {
    echo -n "Checking if Wrangler is installed... "
    if ! command -v wrangler &> /dev/null; then
        echo -e "${RED}FAILED${NC}"
        echo -e "${YELLOW}Installing Wrangler CLI...${NC}"
        npm install -g wrangler
        echo -e "${GREEN}✅ Wrangler installed${NC}"
    else
        echo -e "${GREEN}Already installed${NC}"
    fi
}

# Function to login to Cloudflare
login_cloudflare() {
    echo ""
    echo "🔐 Cloudflare Authentication"
    echo "----------------------------"
    echo "You'll be prompted to authenticate with Cloudflare."
    echo ""
    npx wrangler login
    echo -e "${GREEN}✅ Authenticated${NC}"
}

# Function to verify environment variables
verify_env() {
    echo ""
    echo "📋 Checking Environment Variables"
    echo "----------------------------------"
    
    local required_vars=(
        "NEXT_PUBLIC_SUPABASE_URL"
        "NEXT_PUBLIC_SUPABASE_ANON_KEY"
        "NEXT_PRIVATE_STRIPE_SECRET_KEY"
        "FREEMIUS_API_URL"
    )
    
    local missing=0
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            echo -e "❌ ${YELLOW}${var}${NC} not set"
            missing=$((missing + 1))
        else
            echo -e "✅ ${var}"
        fi
    done
    
    if [ $missing -gt 0 ]; then
        echo -e "${YELLOW}Warning: ${missing} environment variable(s) are missing.${NC}"
        echo "Set them in your shell or .env file before building."
        return 1
    fi
    
    echo -e "${GREEN}✅ All required environment variables set${NC}"
}

# Function to build the app
build_app() {
    echo ""
    echo "🏗️  Building Application"
    echo "------------------------"
    echo "Running: npm run web:build"
    
    npm run web:build
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Build successful${NC}"
        
        # Check if .next directory exists
        if [ -d ".next" ]; then
            echo -e "${GREEN}✅ .next directory created${NC}"
        else
            echo -e "${RED}❌ Build completed but .next directory not found${NC}"
            exit 1
        fi
    else
        echo -e "${RED}❌ Build failed${NC}"
        exit 1
    fi
}

# Function to deploy
deploy_to_cloudflare() {
    echo ""
    echo "☁️  Deploying to Cloudflare Pages"
    echo "---------------------------------"
    
    local project_name=${1:-"takwa"}
    local branch=${2:-"main"}
    
    echo "Project: ${project_name}"
    echo "Branch: ${branch}"
    
    # Create project if it doesn't exist
    echo "Creating/Verifying project..."
    npx wrangler pages project list | grep -q "$project_name" || \
        npx wrangler pages project create "$project_name" --yes
    
    # Deploy
    echo "Deploying..."
    npx wrangler pages deploy .next --project-name="$project_name" --branch="$branch"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Deployment successful!${NC}"
    else
        echo -e "${RED}❌ Deployment failed${NC}"
        exit 1
    fi
}

# Function to show project status
show_status() {
    echo ""
    echo "📊 Project Status"
    echo "-----------------"
    npx wrangler pages project list
}

# Main function
main() {
    local command=$1
    shift
    
    case $command in
        "install")
            check_wrangler
            ;;
        "login")
            login_cloudflare
            ;;
        "env")
            verify_env
            ;;
        "build")
            build_app
            ;;
        "deploy")
            local project=${1:-"takwa"}
            local branch=${2:-"main"}
            deploy_to_cloudflare "$project" "$branch"
            ;;
        "all")
            # Run full pipeline: install → login → env → build → deploy
            check_wrangler
            login_cloudflare
            verify_env || true  # Continue even if env vars missing (can be set in dashboard)
            build_app
            deploy_to_cloudflare "${@:-takwa}"
            ;;
        "status")
            show_status
            ;;
        *)
            echo "Usage: cloudflare-deploy.sh [command] [options]"
            echo ""
            echo "Commands:"
            echo "  install      Install Wrangler CLI"
            echo "  login        Login to Cloudflare"
            echo "  env          Verify environment variables"
            echo "  build        Build the application"
            echo "  deploy [name] [branch]  Deploy to Cloudflare Pages"
            echo "  all          Run complete pipeline (install → login → build → deploy)"
            echo "  status       Show project status"
            echo ""
            echo "Examples:"
            echo "  ./cloudflare-deploy.sh install"
            echo "  ./cloudflare-deploy.sh all takwa main"
            echo "  ./cloudflare-deploy.sh deploy my-project production"
            ;;
    esac
}

main "$@"
