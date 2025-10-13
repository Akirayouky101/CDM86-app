/**
 * Vercel Serverless Function per upload immagini su Vercel Blob
 * Endpoint: /api/upload
 */

import { put } from '@vercel/blob';
import multiparty from 'multiparty';

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
    const file = files.file[0];
    
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
    const extension = file.originalFilename.split('.').pop();
    const filename = `promotions/${timestamp}-${random}.${extension}`;

    // Upload to Vercel Blob
    const blob = await put(filename, file.path, {
      access: 'public',
      addRandomSuffix: false,
    });

    // Return URL
    return res.status(200).json({
      success: true,
      url: blob.url,
      filename: filename,
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
