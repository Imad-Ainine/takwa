# Cloudflare Pages Deployment Script (PowerShell)
# For Windows users who prefer PowerShell

param(
    [string]$Command = "help",
    [string]$ProjectName = "takwa",
    [string]$Branch = "main"
)

Write-Host "🚀 Takwa Cloudflare Pages Deployment" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

# Function to check if Wrangler is installed
function Test-Wrangler {
    Write-Host -NoNewline "Checking if Wrangler is installed... "

    try {
        $null = Get-Command wrangler -ErrorAction Stop
        Write-Host "✅ Already installed" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "❌ Not found" -ForegroundColor Red
        Write-Host "`nInstalling Wrangler CLI..." -ForegroundColor Yellow

        npm install -g wrangler

        if ($?) {
            Write-Host "✅ Wrangler installed successfully" -ForegroundColor Green
            return $true
        } else {
            Write-Host "❌ Failed to install Wrangler" -ForegroundColor Red
            return $false
        }
    }
}

# Function to login to Cloudflare
function Login-Cloudflare {
    Write-Host "`n🔐 Cloudflare Authentication" -ForegroundColor Cyan
    Write-Host "-----------------------------------------------" -ForegroundColor Cyan
    Write-Host "You'll be prompted to authenticate with Cloudflare." -ForegroundColor White

    npx wrangler login

    if ($?) {
        Write-Host "✅ Authenticated successfully" -ForegroundColor Green
    } else {
        Write-Host "❌ Authentication failed" -ForegroundColor Red
        exit 1
    }
}

# Function to verify environment variables
function Verify-Env {
    Write-Host "`n📋 Checking Environment Variables" -ForegroundColor Cyan
    Write-Host "---------------------------------------" -ForegroundColor Cyan

    $requiredVars = @(
        "NEXT_PUBLIC_SUPABASE_URL",
        "NEXT_PUBLIC_SUPABASE_ANON_KEY",
        "NEXT_PRIVATE_STRIPE_SECRET_KEY",
        "FREEMIUS_API_URL"
    )

    $missing = 0
    foreach ($var in $requiredVars) {
        # $env:$var is invalid (the drive ref can't contain a variable); resolve dynamically instead
        $value = (Get-Variable -Name "env:$var" -ErrorAction SilentlyContinue).Value
        if ([string]::IsNullOrEmpty($value)) {
            Write-Host "⚠️  $var not set" -ForegroundColor Yellow
            $missing++
        } else {
            Write-Host "✅ $var" -ForegroundColor Green
        }
    }

    if ($missing -gt 0) {
        Write-Host "`nWarning: $missing environment variable(s) are missing." -ForegroundColor Yellow
        Write-Host "Set them in your shell or .env file before building." -ForegroundColor Yellow
        return $false
    }

    Write-Host "`n✅ All required environment variables set" -ForegroundColor Green
    return $true
}

# Function to build the app
function Build-App {
    Write-Host "`n🏗️  Building Application" -ForegroundColor Cyan
    Write-Host "---------------------------------------------------------------" -ForegroundColor Cyan
    Write-Host "Running: npm run web:build" -ForegroundColor White

    npm run web:build

    if ($?) {
        Write-Host "✅ Build successful!" -ForegroundColor Green

        if (Test-Path ".next") {
            Write-Host "✅ .next directory created" -ForegroundColor Green
        } else {
            Write-Host "❌ Build completed but .next directory not found" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "❌ Build failed" -ForegroundColor Red
        exit 1
    }
}

# Function to deploy
function Deploy-Cloudflare {
    param([string]$project = "takwa", [string]$branch = "main")

    Write-Host "`n☁️  Deploying to Cloudflare Pages" -ForegroundColor Cyan
    Write-Host "-----------------------------------------------------------------------" -ForegroundColor Cyan
    Write-Host "Project: $project" -ForegroundColor White
    Write-Host "Branch: $branch" -ForegroundColor White

    # Create project if it doesn't exist
    Write-Host "Creating/Verifying project..." -ForegroundColor White

    # Check if project exists
    $projects = npx wrangler pages project list 2>&1 | Out-String
    if ($projects -notlike "*$project*") {
        npx wrangler pages project create "$project" --yes --output=json 2>$null
    }

    # Deploy
    Write-Host "Deploying .next directory..." -ForegroundColor White

    # Deploy command might fail if project doesn't exist yet
    $deployResult = npx wrangler pages deploy .next --project-name="$project" --branch="$branch" --output-json 2>&1

    if ($deployResult -match "Successfully deployed") {
        Write-Host "✅ Deployment successful!" -ForegroundColor Green
    } elseif ($deployResult -match "success|success" -or $LASTEXITCODE -eq 0) {
        Write-Host "✅ Deployment successful!" -ForegroundColor Green
    } else {
        Write-Host "`nDeployment output:" -ForegroundColor Yellow
        Write-Host $deployResult
        Write-Host "❌ Deployment status unknown, check manually" -ForegroundColor Red
    }
}

# Main switch statement
switch ($Command.ToLower()) {
    "install" {
        Test-Wrangler
    }
    "login" {
        Login-Cloudflare
    }
    "env" {
        Verify-Env
    }
    "build" {
        Build-App
    }
    "deploy" {
        Deploy-Cloudflare $ProjectName $Branch
    }
    "all" {
        # Run full pipeline
        Write-Host "`n🔄 Running Complete Pipeline..." -ForegroundColor Cyan

        Test-Wrangler
        Login-Cloudflare
        if (-not (Verify-Env)) {
            Write-Host "`n⚠️  Continuing despite missing env vars" -ForegroundColor Yellow
        }
        Build-App
        Deploy-Cloudflare $ProjectName $Branch

        Write-Host "`n🎉 Deployment complete!" -ForegroundColor Green
    }
    "status" {
        Write-Host "`n📊 Cloudflare Pages Projects" -ForegroundColor Cyan
        npx wrangler pages project list
    }
    default {
        Write-Host "`nUsage: `n"
        Write-Host "  .\cloudflare-deploy.ps1 [command] [options]" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Commands:" -ForegroundColor Yellow
        Write-Host "  install      Install Wrangler CLI" -ForegroundColor White
        Write-Host "  login        Login to Cloudflare" -ForegroundColor White
        Write-Host "  env          Verify environment variables" -ForegroundColor White
        Write-Host "  build        Build the application" -ForegroundColor White
        Write-Host "  deploy       Deploy to Cloudflare Pages" -ForegroundColor White
        Write-Host "  all          Run complete pipeline (install → login → build → deploy)" -ForegroundColor White
        Write-Host "  status       Show project status" -ForegroundColor White
        Write-Host ""
        Write-Host "Examples:" -ForegroundColor Yellow
        Write-Host "  .\cloudflare-deploy.ps1 install" -ForegroundColor White
        Write-Host "  .\cloudflare-deploy.ps1 all takwa main" -ForegroundColor White
        Write-Host "  .\cloudflare-deploy.ps1 deploy my-project production" -ForegroundColor White
    }
}
