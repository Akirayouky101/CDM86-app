/**
 * API Endpoint per impostare il referral dopo registrazione
 * Usa service_role per bypassare RLS in modo sicuro
 */

import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

// Client con service_role (bypassa RLS)
const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey);

export default async function handler(req, res) {
    // Solo POST
    if (req.method !== 'POST') {
        return res.status(405).json({ error: 'Method not allowed' });
    }

    try {
        const { userId, referredById, organizationId } = req.body;

        // Validazione
        if (!userId) {
            return res.status(400).json({ error: 'userId is required' });
        }

        if (!referredById && !organizationId) {
            return res.status(400).json({ error: 'Either referredById or organizationId is required' });
        }

        // Verifica che l'utente esista
        const { data: user, error: userError } = await supabaseAdmin
            .from('users')
            .select('id, referred_by_id, organization_id')
            .eq('id', userId)
            .single();

        if (userError || !user) {
            return res.status(404).json({ error: 'User not found' });
        }

        // Non sovrascrivere se già impostato
        if (user.referred_by_id || user.organization_id) {
            return res.status(400).json({ 
                error: 'Referral already set',
                data: user
            });
        }

        // Prepara update
        const updateData = {};
        if (referredById) {
            // Verifica che il referrer esista
            const { data: referrer, error: referrerError } = await supabaseAdmin
                .from('users')
                .select('id')
                .eq('id', referredById)
                .single();

            if (referrerError || !referrer) {
                return res.status(404).json({ error: 'Referrer not found' });
            }

            updateData.referred_by_id = referredById;
        }

        if (organizationId) {
            // Verifica che l'organizzazione esista
            const { data: org, error: orgError } = await supabaseAdmin
                .from('organizations')
                .select('id')
                .eq('id', organizationId)
                .single();

            if (orgError || !org) {
                return res.status(404).json({ error: 'Organization not found' });
            }

            updateData.organization_id = organizationId;
        }

        // UPDATE con service_role (bypassa RLS)
        const { data: updatedUser, error: updateError } = await supabaseAdmin
            .from('users')
            .update(updateData)
            .eq('id', userId)
            .select()
            .single();

        if (updateError) {
            console.error('Update error:', updateError);
            return res.status(500).json({ error: 'Failed to update user' });
        }

        console.log('✅ Referral set successfully:', {
            userId,
            referredById,
            organizationId
        });

        return res.status(200).json({
            success: true,
            data: updatedUser
        });

    } catch (error) {
        console.error('API error:', error);
        return res.status(500).json({ error: error.message });
    }
}
