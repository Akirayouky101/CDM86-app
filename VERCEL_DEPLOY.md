# 🚀 Deploy CDM86 su Vercel

## 📋 Prerequisiti
- Account Vercel (https://vercel.com)
- Repository GitHub: `Akirayouky101/CDM86-app` (✅ già configurata)
- Credenziali Supabase

## 🔧 Passaggi per il Deploy

### 1. Importa il Progetto su Vercel

1. Vai su [vercel.com](https://vercel.com) e fai login
2. Clicca su **"Add New Project"**
3. Seleziona **"Import Git Repository"**
4. Cerca e seleziona `Akirayouky101/CDM86-app`
5. Clicca su **"Import"**

### 2. Configura le Variabili d'Ambiente

Nel pannello di configurazione del progetto, vai su **"Environment Variables"** e aggiungi le seguenti variabili:

#### 🔴 VARIABILI OBBLIGATORIE

```
SUPABASE_URL=https://uchrjlngfzfibcpdxtky.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVjaHJqbG5nZnpmaWJjcGR4dGt5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAwMzEyMDYsImV4cCI6MjA3NTYwNzIwNn0.64JK3OhYJi2YtrErctNAp_sCcSHwB656NVLdooyceOM
NODE_ENV=production
```

#### 🟡 VARIABILI OPZIONALI (se necessarie)

```
PORT=3000
ALLOWED_ORIGINS=https://your-vercel-domain.vercel.app,https://cdm86.com
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
JWT_EXPIRE=7d
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your-email@gmail.com
EMAIL_PASS=your-app-password
EMAIL_FROM=CDM86 <noreply@cdm86.com>
```

### 3. Configura Build Settings

Vercel dovrebbe rilevare automaticamente le impostazioni dal `vercel.json`:

- **Framework Preset**: Other
- **Build Command**: `echo 'Static site - no build needed'`
- **Output Directory**: `.`
- **Install Command**: (lascia vuoto per siti statici)

### 4. Deploy

1. Clicca su **"Deploy"**
2. Attendi che il deploy sia completato (circa 1-2 minuti)
3. Vercel ti fornirà un URL come: `https://cdm86-app.vercel.app`

### 5. Configura il Dominio Personalizzato (Opzionale)

1. Vai su **Settings** > **Domains**
2. Aggiungi il tuo dominio personalizzato (es. `cdm86.com`)
3. Segui le istruzioni per configurare i DNS

## 🔄 Aggiornamenti Automatici

Ogni volta che fai un push su GitHub:
```bash
git add .
git commit -m "Update"
git push origin main
```

Vercel farà automaticamente il re-deploy! 🎉

## ✅ Verifica il Deploy

Dopo il deploy, verifica che:
- [ ] Il sito sia accessibile all'URL fornito da Vercel
- [ ] Le variabili d'ambiente siano configurate correttamente
- [ ] L'autenticazione con Supabase funzioni
- [ ] Le promozioni vengano caricate correttamente

## 🐛 Troubleshooting

### Errore 404
- Verifica che `vercel.json` contenga le route corrette
- Controlla che `index.html` sia nella root del progetto

### Errore di autenticazione Supabase
- Verifica che `SUPABASE_URL` e `SUPABASE_ANON_KEY` siano corrette
- Controlla che il dominio Vercel sia autorizzato in Supabase (Authentication > URL Configuration)

### Funzioni API non funzionanti
- Le funzioni serverless devono essere nella cartella `/api`
- Verifica che i file abbiano l'estensione `.js`

## 📝 Note Importanti

1. **Supabase URL Configuration**: Vai su Supabase Dashboard > Settings > API > Site URL e aggiungi l'URL di Vercel
2. **CORS**: Assicurati che Vercel sia autorizzato nelle impostazioni CORS di Supabase
3. **Redirect URIs**: Aggiungi l'URL di Vercel ai redirect URIs autorizzati in Supabase

## 🔗 Link Utili

- [Vercel Dashboard](https://vercel.com/dashboard)
- [Supabase Dashboard](https://app.supabase.com)
- [Vercel Documentation](https://vercel.com/docs)
- [Repository GitHub](https://github.com/Akirayouky101/CDM86-app)
