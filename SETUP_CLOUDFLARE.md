# Cloudflare Setup Guide

Follow these steps to configure Cloudflare Pages for your Takwa web application.

## Step 1: Create Cloudflare API Token

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Navigate to **Profile** → **API Tokens** → **Create token**
3. Choose template **"Edit Cloudflare Pages"**
4. Set permissions:
   - **Account**: Read
   - **Cloudflare Pages**: Edit
5. Save the token (copy it immediately - you won't see it again!)

## Step 2: Add GitHub Secrets

In your GitHub repository:
1. Go to **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Add these secrets:

| Secret Name | Value |
|-------------|-------|
| `CF_API_TOKEN` | Your API token from Step 1 |
| `CF_TEAM_ID` | Your Cloudflare Team ID |

**How to find Team ID:**
- Run: `npx wrangler whoami` after logging in with `wrangler login`
- Look for "You are" line, the UUID is your team ID

Or manually find it at:
- Cloudflare Dashboard → Account Home → Copy Team ID (bottom of page)

## Step 3: Configure Cloudflare Pages Project

### Option A: Via Cloudflare Dashboard (Recommended for first deploy)

1. Go to **Workers & Pages** → **Create application** → **Pages**
2. Connect your GitHub account
3. Select repository: `Imad-Ainine/takwa`
4. Branch: `main`
5. **Build settings:**
   - Framework preset: **None**
   - Build command: `npm run web:build`
   - Build output directory: `.next`
   - Root directory: `/`
6. **Environment variables:** Add these under "Environment Variables"
   ```
   NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
   NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
   FREEMIUS_API_URL=https://freemius.com/api/2/1
   NEXT_PUBLIC_ENVIRONMENT=production
   ```
7. Click **Deploy**

### Option B: Via CLI

```bash
# Install Wrangler
npm install -g wrangler

# Login
npx wrangler login

# Create project
npx wrangler pages project create takwa --team-id YOUR_TEAM_ID
```

## Step 4: Configure Custom Domain

1. In Cloudflare Pages dashboard, go to **Custom domains**
2. Click **Set up custom domain**
3. Enter your domain: `takwa.com`
4. Follow DNS configuration instructions
5. Wait for propagation (usually takes a few minutes)

## Step 5: Test Deployment

### Manual Test (Optional)

Before committing, test locally:

```bash
# PowerShell
.\cloudflare-deploy.ps1 all takwa main

# Or Bash
./cloudflare-deploy.sh all takwa main
```

### Automatic Deployment

After setup, deployments happen automatically when you:
- **Push to `main`**: Deploys to production (`takwa.com`)
- **Open PR**: Creates preview deployment (`takwa-[random].pages.dev`)

## Step 6: Verify Deployment

Check the following:

1. **Deployment logs:**
   - Go to Cloudflare Pages → Your site → Deployments
   - Click the latest deployment → View logs
   
2. **Production URL:**
   ```
   https://takwa.com
   ```
   
3. **Preview URLs:**
   ```
   https://takwa-[random-hash]-takwa.pages.dev
   ```

## Troubleshooting

### Issue: Build Fails

**Symptoms:** Deployment fails during build step

**Solutions:**
1. Check `wrangler.toml` build command matches package.json script
2. Ensure all dependencies are listed in root `package.json`
3. Verify Node.js version compatibility (should be v20.x)
4. Check deployment logs in Cloudflare dashboard

### Issue: API Routes Not Working

**Symptoms:** `/api/*` endpoints return 404

**Solution:** Cloudflare Pages supports serverless functions via Middleware or Edge Functions. For Next.js App Router API routes, ensure you're using the proper structure.

### Issue: Environment Variables Missing

**Symptoms:** Runtime errors about missing env vars

**Solutions:**
1. Go to Cloudflare Pages → Settings → Environment Variables
2. Ensure vars match exactly (case-sensitive)
3. Redeploy after adding/changing variables

### Issue: Preview Deployments Don't Work

**Symptoms:** PR previews not creating

**Solution:** GitHub Actions workflow checks for PR events. If failing, check:
- Workflow status tab in GitHub
- Run logs for specific errors
- Permissions on the GitHub token

## Migration Checklist

Complete this checklist to finalize migration from Vercel:

- [ ] Create Cloudflare API token
- [ ] Add GitHub secrets (`CF_API_TOKEN`, `CF_TEAM_ID`)
- [ ] Configure Cloudflare Pages project in dashboard
- [ ] Set environment variables in Cloudflare
- [ ] Add custom domain to Cloudflare Pages
- [ ] Verify DNS propagation
- [ ] Test manual deployment
- [ ] Delete or disconnect from Vercel (optional)

## Next Steps

After successful migration:

1. **Monitor first few deployments** to ensure everything works
2. **Update documentation** to reflect new deployment flow
3. **Clean up old resources** if no longer needed (Vercel app)
4. **Set up monitoring/alerts** for deployment failures

## Support

If you encounter issues:

1. Check deployment logs in Cloudflare dashboard
2. Review this guide and verify each step
3. Enable verbose logging: set `DEBUG=wrangler*` in CI/CD
4. Contact support or open an issue

---

**Note:** Your deployment automation is now handled by GitHub Actions. Pushing to `main` will trigger automatic builds and deployments to Cloudflare Pages. 🚀
