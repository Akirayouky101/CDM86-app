/**
 * Vercel Serverless Function per upload immagini su Vercel Blob
 * Endpoint: /api/upload
 * 
 * Crea due versioni dell'immagine:
 * - Thumbnail: 120x80px per le card (crop al centro)
 * - Full: 800x600px per i dettagli (mantiene proporzioni)
 */

import { put } from '@vercel/blob';
import multiparty from 'multiparty';
import fs from 'fs';
import sharp from 'sharp';

export const config = {
  api: {
    bodyParser: false,
  },
};

export default async function handler(req, res) {
  // Solo POST
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    // Parse multipart form data
    const form = new multiparty.Form();
    
    const { fields, files } = await new Promise((resolve, reject) => {
      form.parse(req, (err, fields, files) => {
        if (err) reject(err);
        resolve({ fields, files });
      });
    });

    // Get file
    const file = files.file?.[0];
    
    if (!file) {
      return res.status(400).json({ error: 'No file uploaded' });
    }

    // Validate file type
    const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp', 'image/gif'];
    if (!allowedTypes.includes(file.headers['content-type'])) {
      return res.status(400).json({ error: 'Invalid file type. Only images allowed.' });
    }

    // Validate file size (max 5MB)
    if (file.size > 5 * 1024 * 1024) {
      return res.status(400).json({ error: 'File too large. Max 5MB.' });
    }

    // Generate unique filename
    const timestamp = Date.now();
    const random = Math.random().toString(36).substring(7);
    const extension = 'jpg'; // Converti sempre in JPG per consistenza

    // Read original file
    const originalBuffer = fs.readFileSync(file.path);

    // Create THUMBNAIL version (120x80px - crop al centro per le card)
    const thumbnailBuffer = await sharp(originalBuffer)
      .resize(120, 80, {
        fit: 'cover',
        position: 'center'
      })
      .jpeg({ quality: 90 })
      .toBuffer();

    // Create FULL version (800x600px - mantiene proporzioni per i dettagli)
    const fullBuffer = await sharp(originalBuffer)
      .resize(800, 600, {
        fit: 'inside',
        withoutEnlargement: true
      })
      .jpeg({ quality: 85 })
      .toBuffer();

    // Upload thumbnail
    const thumbnailFilename = `promotions/thumb-${timestamp}-${random}.${extension}`;
    const thumbnailBlob = await put(thumbnailFilename, thumbnailBuffer, {
      access: 'public',
      addRandomSuffix: false,
      contentType: 'image/jpeg',
    });

    // Upload full image
    const fullFilename = `promotions/full-${timestamp}-${random}.${extension}`;
    const fullBlob = await put(fullFilename, fullBuffer, {
      access: 'public',
      addRandomSuffix: false,
      contentType: 'image/jpeg',
    });

    // Delete temp file
    fs.unlinkSync(file.path);

    // Return both URLs
    return res.status(200).json({
      success: true,
      url: fullBlob.url,           // URL immagine full per i dettagli
      thumbnailUrl: thumbnailBlob.url,  // URL thumbnail per le card
      filename: fullFilename,
    });

  } catch (error) {
    console.error('Upload error:', error);
    return res.status(500).json({
      success: false,
      error: 'Upload failed',
      message: error.message,
    });
  }
}
