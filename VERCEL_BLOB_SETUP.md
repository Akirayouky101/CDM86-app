# 🔑 Setup Vercel Blob Storage Token

## ❌ Problema Attuale

L'upload fallisce perché manca `BLOB_READ_WRITE_TOKEN` nel file `.env.local`.

---

## ✅ Soluzione: Ottieni il Token Vercel Blob

### 1. **Vai su Vercel Dashboard**
```
https://vercel.com/dashboard/stores
```

### 2. **Crea un Blob Store** (se non esiste)
- Click su **"Create Database"** o **"Create Store"**
- Seleziona **"Blob"**
- Nome: `cdm86-images` (o qualsiasi nome)
- Click **"Create"**

### 3. **Copia il Token**
- Nella pagina del Blob store appena creato
- Troverai **"Read-Write Token"**
- Click su **"Copy"** o **"Reveal"**
- Il token inizia con: `vercel_blob_rw_...`

### 4. **Aggiungi il Token al .env.local**

Apri il file `/Users/akirayouky/Desktop/Siti/CDM86-NEW/.env.local` e sostituisci:

```bash
BLOB_READ_WRITE_TOKEN=
```

Con:

```bash
BLOB_READ_WRITE_TOKEN=vercel_blob_rw_XXXXXXXXXXXXXXXXXXXXXXXX
```

### 5. **Riavvia Vercel Dev**

```bash
# Ferma il server (Ctrl+C nel terminale)
# Riavvia:
cd /Users/akirayouky/Desktop/Siti/CDM86-NEW
vercel dev
```

---

## 🧪 Test Upload

Dopo aver configurato il token:

1. Vai su: http://localhost:3000/test-upload-vercel.html
2. Seleziona tipo immagine (Card/Hero/About/Logo)
3. Clicca su area upload e scegli immagine
4. ✅ Dovrebbe caricare su Vercel Blob e mostrare URL

---

## 📝 Note

- Il token è **SEGRETO** - non commitarlo su Git
- `.env.local` è già in `.gitignore`
- In produzione Vercel usa automaticamente il token dal Dashboard
- Questo setup è solo per **test in locale**

---

## 🎯 Alternative (se non hai account Vercel)

Se non puoi ottenere il token ora, possiamo:

1. **Usare placeholder temporaneo** - simula upload con base64
2. **Testare solo in produzione** - deploy su Vercel direttamente
3. **Usare altro storage** - Cloudinary, AWS S3, etc.

Dimmi cosa preferisci! 🚀
