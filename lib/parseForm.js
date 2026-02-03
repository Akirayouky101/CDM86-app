/**
 * Parse multipart/form-data for Vercel Serverless Functions
 * Alternativa leggera a multiparty che funziona con Vercel
 */

export async function parseForm(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    
    req.on('data', chunk => {
      chunks.push(chunk);
    });
    
    req.on('end', () => {
      try {
        const buffer = Buffer.concat(chunks);
        const contentType = req.headers['content-type'] || '';
        
        if (!contentType.includes('multipart/form-data')) {
          return reject(new Error('Content-Type must be multipart/form-data'));
        }
        
        // Extract boundary
        const boundaryMatch = contentType.match(/boundary=(.+?)(?:;|$)/);
        if (!boundaryMatch) {
          return reject(new Error('No boundary found in Content-Type'));
        }
        
        const boundary = '--' + boundaryMatch[1];
        const parts = buffer.toString('binary').split(boundary);
        
        const fields = {};
        const files = {};
        
        for (const part of parts) {
          if (!part || part === '--\r\n' || part === '--') continue;
          
          // Parse headers
          const headerEndIndex = part.indexOf('\r\n\r\n');
          if (headerEndIndex === -1) continue;
          
          const headerSection = part.substring(0, headerEndIndex);
          const bodySection = part.substring(headerEndIndex + 4, part.length - 2); // Remove trailing \r\n
          
          // Extract content-disposition
          const nameMatch = headerSection.match(/name="([^"]+)"/);
          if (!nameMatch) continue;
          
          const name = nameMatch[1];
          const filenameMatch = headerSection.match(/filename="([^"]+)"/);
          
          if (filenameMatch) {
            // It's a file
            const filename = filenameMatch[1];
            const contentTypeMatch = headerSection.match(/Content-Type: (.+)/i);
            const mimetype = contentTypeMatch ? contentTypeMatch[1].trim() : 'application/octet-stream';
            
            // Convert binary string back to buffer
            const fileBuffer = Buffer.from(bodySection, 'binary');
            
            files[name] = {
              filename,
              mimetype,
              buffer: fileBuffer,
              size: fileBuffer.length
            };
          } else {
            // It's a field
            fields[name] = bodySection;
          }
        }
        
        resolve({ fields, files });
      } catch (error) {
        reject(error);
      }
    });
    
    req.on('error', reject);
  });
}
