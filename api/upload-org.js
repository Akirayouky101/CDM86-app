/**
 * Vercel Serverless Function per upload immagini ORGANIZZAZIONI su Vercel Blob
 * Endpoint: /api/upload-org
 * 
 * Per card/pagine aziendali - sostituisce Supabase Storage
 * Crea versione ottimizzata con Sharp
 */

import { put } from '@vercel/blob';
import { parseForm } from '../lib/parseForm.js';
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
    // Check if BLOB token is configured
    if (!process.env.BLOB_READ_WRITE_TOKEN) {
      console.error('❌ BLOB_READ_WRITE_TOKEN not configured!');
      return res.status(500).json({ 
        error: 'Server configuration error',
        message: 'BLOB_READ_WRITE_TOKEN not found. Please add it to .env file.',
        hint: 'Get your token from https://vercel.com/dashboard/stores'
      });
    }

    console.log('📥 Parsing form data...');
    
    // Parse multipart form data
    const { fields, files } = await parseForm(req);
    
    console.log('📋 Fields:', fields);
    console.log('📁 Files:', files ? Object.keys(files) : 'none');

    // Get file
    const file = files.file;
    
    if (!file) {
      console.error('❌ No file in upload');
      return res.status(400).json({ error: 'No file uploaded' });
    }

    // Validate file type
    const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp', 'image/gif'];
    if (!allowedTypes.includes(file.mimetype)) {
      return res.status(400).json({ error: 'Invalid file type. Only images allowed.' });
    }

    // Validate file size (max 10MB per immagini organizzazioni)
    if (file.size > 10 * 1024 * 1024) {
      return res.status(400).json({ error: 'File too large. Max 10MB.' });
    }

    // Get upload type from fields (hero/about/logo/card)
    const uploadType = fields.type || 'general';
    const userId = fields.userId || 'anonymous';

    console.log('🎯 Upload type:', uploadType);
    console.log('👤 User ID:', userId);

    // Generate unique filename
    const timestamp = Date.now();
    const random = Math.random().toString(36).substring(7);

    // Use buffer directly from parsed file
    const originalBuffer = file.buffer;

    // Ottimizza in base al tipo
    let optimizedBuffer;
    let width, height;

    switch (uploadType) {
      case 'hero':
        // Hero images - large banner (1920x600)
        width = 1920;
        height = 600;
        break;
      case 'about':
        // About images - medium (800x600)
        width = 800;
        height = 600;
        break;
      case 'logo':
        // Logo - small square (400x400)
        width = 400;
        height = 400;
        break;
      case 'card':
        // Card images - standard (800x450)
        width = 800;
        height = 450;
        break;
      default:
        // Default - medium size
        width = 1200;
        height = 900;
    }

    // Optimize and resize
    optimizedBuffer = await sharp(originalBuffer)
      .resize(width, height, {
        fit: 'inside',
        withoutEnlargement: false,
        background: { r: 255, g: 255, b: 255, alpha: 0 } // Transparent background
      })
      .png({ quality: 85, compressionLevel: 6 })
      .toBuffer();

    // Upload to Vercel Blob
    const filename = `organizations/${userId}/${uploadType}-${timestamp}-${random}.png`;
    
    console.log('☁️ Uploading to Vercel Blob:', filename);
    
    const blob = await put(filename, optimizedBuffer, {
      access: 'public',
      addRandomSuffix: false,
      contentType: 'image/png',
    });

    console.log('✅ Upload successful:', blob.url);

    // Return URL
    return res.status(200).json({
      success: true,
      url: blob.url,
      publicUrl: blob.url, // Compatibility con Supabase Storage API
      filename: filename,
      type: uploadType,
      size: optimizedBuffer.length,
      dimensions: { width, height }
    });

  } catch (error) {
    console.error('❌ Upload error:', error);
    return res.status(500).json({
      success: false,
      error: 'Upload failed',
      message: error.message,
    });
  }
}
