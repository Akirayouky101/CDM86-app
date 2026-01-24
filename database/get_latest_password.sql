-- =====================================================
-- VEDERE PASSWORD ULTIMA ORGANIZZAZIONE CREATA
-- =====================================================

SELECT 
  o.name AS "Nome Azienda",
  o.email AS "Email Login",
  otp.temp_password AS "🔑 PASSWORD",
  o.referral_code AS "Codice Referral",
  o.active AS "Attiva",
  otp.created_at AS "Creata il"
FROM organization_temp_passwords otp
JOIN organizations o ON o.id = otp.organization_id
ORDER BY otp.created_at DESC
LIMIT 1;

-- =====================================================
-- TUTTE LE PASSWORD NON ANCORA INVIATE
-- =====================================================

/*
SELECT 
  o.name AS "Azienda",
  o.email AS "Email",
  otp.temp_password AS "Password",
  otp.email_sent AS "Email Inviata",
  otp.created_at AS "Creata"
FROM organization_temp_passwords otp
JOIN organizations o ON o.id = otp.organization_id
WHERE otp.email_sent = false
ORDER BY otp.created_at DESC;
*/
