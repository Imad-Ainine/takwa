# Cloudflare Pages Deployment Setup

This document outlines how to deploy your Takwa web application to Cloudflare Pages (replacing Vercel).

## Quick Start

### 1. Set Up Cloudflare Project

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Navigate to **Workers & Pages** → **Create application** → **Pages**
3. Connect your GitHub repository (`Imad-Ainine/takwa`)
4. Select the branch you want to deploy from (usually `main`)

### 2. Configure Build Settings

| Setting | Value |
|---------|-------|
| Framework Preset | None |
| Build command | `npm run web:build` |
| Build output directory | `.next` |
| Root Directory | `/` (monorepo root) |

### 3. Environment Variables

Set these in Cloudflare Pages Dashboard → **Environment Variables**:

```env
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
NEXT_PRIVATE_STRIPE_SECRET_KEY=sk_...
NEXT_PUBLIC_ENVIRONMENT=production
FREEMIUS_API_URL=https://freemius.com/api/2/1
```

### 4. Deploy via Git

The deployment is now fully automated via GitHub Actions. When you push to the `main` branch:

- **Pull Request**: Runs tests and builds only (no deployment)
- **Push to main**: Deploys automatically to Cloudflare Pages

## Manual Deployment

If you want to deploy manually without pushing to GitHub:

```bash
# Install Wrangler CLI globally
npm install -g wrangler

# Login to Cloudflare
npx wrangler login

# Build your Next.js app
npm run web:build

# Deploy to Cloudflare Pages
npx wrangler pages deploy .next --project-name=takwa
```

## Project Configuration

The project uses `wrangler.toml` for Cloudflare Pages configuration:

```toml
name = "takwa"
compatibility_date = "2024-11-01"
compatibility_flags = [ "nodejs_compat" ]

[build]
command = "npm run web:build"
working_directory = "."

[[redirects]]
for = "/*"
source = "/_next/static/*"
destination = "/_next/static/*"
status_code = 200

[[redirects]]
for = "/*"
source = "/api/*"
destination = "/api/*"
status_code = 200
```

## CI/CD Workflow

See `.github/workflows/deploy-web.yml`:

1. **Checkout** code
2. **Setup Node.js** (v20.x) with npm caching
3. **Install dependencies**
4. **Build web application** (`npm run web:build`)
5. **Lint** the application
6. **Deploy to Cloudflare Pages** (if pushed to main)

## URLs

After deployment, your site will be available at:

- **Production**: `https://takwa.com` (your custom domain)
- **Preview**: `https://takwa-[random]-takwa.pages.dev` (for PR previews)

## Troubleshooting

### Common Issues

1. **Build fails on Cloudflare**: Ensure all dependencies are in `package.json` and not dev-only
2. **API routes not working**: Cloudflare Pages supports serverless functions, ensure your API endpoints use Next.js App Router patterns
3. **Environment variables missing**: Check they're set in Cloudflare dashboard with correct names

### Logs and Monitoring

- View deployment logs: Cloudflare Pages → **Deployment details** → **View logs**
- Monitor performance: Cloudflare Analytics or third-party tools like Lighthouse

## Comparing with Vercel

| Feature | Vercel | Cloudflare Pages |
|---------|--------|------------------|
| Git-based deployment | ✅ | ✅ |
| Preview deployments | ✅ | ✅ |
| Edge caching | Basic | Advanced (Cloudflare network) |
| Function execution | Serverless | Workers-compatible |
| Pricing | Free tier generous | Free tier very generous |
| Global CDN | Yes | Yes (Cloudflare's edge network) |

## Cleanup (Optional)

To remove Vercel integration:

1. Delete `vercel.json` if no longer needed
2. Disconnect from Vercel Dashboard: Settings → Git → Disconnect Repository
