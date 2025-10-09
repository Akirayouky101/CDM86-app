-- ============================================
-- CDM86 Platform - Update Passwords Only
-- Aggiorna le password degli utenti esistenti
-- ============================================

-- Update password hashes con bcrypt corretti
UPDATE users SET password_hash = '$2a$10$orbh8LRXb5XZBf3LRP6VdeKcpSF868NfQYZFBegW.LEw7QNhA7P4u' 
WHERE email = 'admin@cdm86.com'; -- Admin123!

UPDATE users SET password_hash = '$2a$10$qeTkDMH0dW3mjaAKr4vZWOE2nCZphcfA4D3XdRZPcwfUfY3e2JiXq' 
WHERE email = 'mario.rossi@test.com'; -- User123!

UPDATE users SET password_hash = '$2a$10$1qN1qpuGmvrMf8YEZnlHJu8Co1MzhmTIr.P3X4HFmk3lhhhs3fTni' 
WHERE email = 'lucia.verdi@test.com'; -- Partner123!

UPDATE users SET password_hash = '$2a$10$6mqDcb2SfTcZiPXvTdlsK.9Wsl7PXHKjDliEvqzISOmolLImEptJK' 
WHERE email = 'giovanni.bianchi@test.com'; -- Test123!

UPDATE users SET password_hash = '$2a$10$6mqDcb2SfTcZiPXvTdlsK.9Wsl7PXHKjDliEvqzISOmolLImEptJK' 
WHERE email = 'sara.neri@test.com'; -- Test123!

-- Verifica update
SELECT email, 
       first_name || ' ' || last_name as nome,
       substring(password_hash, 1, 20) as hash_preview
FROM users
ORDER BY created_at;

-- ============================================
-- DONE! Password aggiornate
-- ============================================
-- Credenziali:
--   admin@cdm86.com - Admin123!
--   mario.rossi@test.com - User123!
--   lucia.verdi@test.com - Partner123!
--   giovanni.bianchi@test.com - Test123!
--   sara.neri@test.com - Test123!
