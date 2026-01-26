/**
 * Validatore Codice Fiscale Italiano
 * Verifica che il CF combaci con nome, cognome, data di nascita e sesso
 */

const CodiceFiscale = {
    // Tabelle per calcolo CF
    MESI: { 'A': 1, 'B': 2, 'C': 3, 'D': 4, 'E': 5, 'H': 6, 'L': 7, 'M': 8, 'P': 9, 'R': 10, 'S': 11, 'T': 12 },
    MESI_REVERSE: { 1: 'A', 2: 'B', 3: 'C', 4: 'D', 5: 'E', 6: 'H', 7: 'L', 8: 'M', 9: 'P', 10: 'R', 11: 'S', 12: 'T' },
    
    VOCALI: 'AEIOU',
    CONSONANTI: 'BCDFGHJKLMNPQRSTVWXYZ',
    
    DISPARI: { '0': 1, '1': 0, '2': 5, '3': 7, '4': 9, '5': 13, '6': 15, '7': 17, '8': 19, '9': 21,
               'A': 1, 'B': 0, 'C': 5, 'D': 7, 'E': 9, 'F': 13, 'G': 15, 'H': 17, 'I': 19, 'J': 21,
               'K': 2, 'L': 4, 'M': 18, 'N': 20, 'O': 11, 'P': 3, 'Q': 6, 'R': 8, 'S': 12, 'T': 14,
               'U': 16, 'V': 10, 'W': 22, 'X': 25, 'Y': 24, 'Z': 23 },
    
    PARI: { '0': 0, '1': 1, '2': 2, '3': 3, '4': 4, '5': 5, '6': 6, '7': 7, '8': 8, '9': 9,
            'A': 0, 'B': 1, 'C': 2, 'D': 3, 'E': 4, 'F': 5, 'G': 6, 'H': 7, 'I': 8, 'J': 9,
            'K': 10, 'L': 11, 'M': 12, 'N': 13, 'O': 14, 'P': 15, 'Q': 16, 'R': 17, 'S': 18,
            'T': 19, 'U': 20, 'V': 21, 'W': 22, 'X': 23, 'Y': 24, 'Z': 25 },

    /**
     * Estrae consonanti e vocali da una stringa
     */
    estraiConsonantiVocali(str) {
        const pulito = str.toUpperCase().replace(/[^A-Z]/g, '');
        const consonanti = pulito.split('').filter(c => this.CONSONANTI.includes(c));
        const vocali = pulito.split('').filter(c => this.VOCALI.includes(c));
        return { consonanti, vocali };
    },

    /**
     * Calcola le 3 lettere del cognome
     */
    calcolaCognome(cognome) {
        const { consonanti, vocali } = this.estraiConsonantiVocali(cognome);
        let risultato = consonanti.join('');
        
        if (risultato.length < 3) {
            risultato += vocali.join('');
        }
        
        while (risultato.length < 3) {
            risultato += 'X';
        }
        
        return risultato.substring(0, 3);
    },

    /**
     * Calcola le 3 lettere del nome
     */
    calcolaNome(nome) {
        const { consonanti, vocali } = this.estraiConsonantiVocali(nome);
        
        let risultato;
        if (consonanti.length >= 4) {
            // Se ci sono 4+ consonanti, prendi 1a, 3a, 4a
            risultato = consonanti[0] + consonanti[2] + consonanti[3];
        } else {
            risultato = consonanti.join('');
            if (risultato.length < 3) {
                risultato += vocali.join('');
            }
        }
        
        while (risultato.length < 3) {
            risultato += 'X';
        }
        
        return risultato.substring(0, 3);
    },

    /**
     * Calcola anno (2 cifre)
     */
    calcolaAnno(dataNascita) {
        const anno = dataNascita.getFullYear().toString();
        return anno.substring(2, 4);
    },

    /**
     * Calcola mese (lettera)
     */
    calcolaMese(dataNascita) {
        const mese = dataNascita.getMonth() + 1;
        return this.MESI_REVERSE[mese];
    },

    /**
     * Calcola giorno + sesso
     * Maschio: giorno normale (01-31)
     * Femmina: giorno + 40 (41-71)
     */
    calcolaGiornoSesso(dataNascita, sesso) {
        let giorno = dataNascita.getDate();
        
        if (sesso.toUpperCase() === 'F') {
            giorno += 40;
        }
        
        return giorno.toString().padStart(2, '0');
    },

    /**
     * Calcola il carattere di controllo (ultima lettera)
     */
    calcolaCarattereControllo(cf15) {
        let somma = 0;
        
        for (let i = 0; i < 15; i++) {
            const char = cf15[i];
            if (i % 2 === 0) {
                somma += this.DISPARI[char];
            } else {
                somma += this.PARI[char];
            }
        }
        
        const resto = somma % 26;
        return String.fromCharCode(65 + resto); // 65 = 'A'
    },

    /**
     * Valida formato base del CF (16 caratteri, lettere e numeri)
     */
    validaFormato(cf) {
        if (!cf || cf.length !== 16) {
            return { valid: false, error: 'Il codice fiscale deve essere di 16 caratteri' };
        }
        
        const pattern = /^[A-Z]{6}\d{2}[A-Z]\d{2}[A-Z]\d{3}[A-Z]$/;
        if (!pattern.test(cf.toUpperCase())) {
            return { valid: false, error: 'Formato codice fiscale non valido' };
        }
        
        return { valid: true };
    },

    /**
     * Estrae dati dal CF
     */
    estraiDatiDaCF(cf) {
        cf = cf.toUpperCase();
        
        const anno = parseInt(cf.substring(6, 8));
        const meseLettera = cf[8];
        const giornoStr = cf.substring(9, 11);
        
        let giorno = parseInt(giornoStr);
        let sesso = 'M';
        
        if (giorno > 40) {
            sesso = 'F';
            giorno -= 40;
        }
        
        const mese = this.MESI[meseLettera];
        
        // Determina il secolo (se anno < 30, probabilmente 2000+, altrimenti 1900+)
        const annoCompleto = anno < 30 ? 2000 + anno : 1900 + anno;
        
        return {
            anno: annoCompleto,
            mese,
            giorno,
            sesso
        };
    },

    /**
     * FUNZIONE PRINCIPALE: Valida CF completo con dati anagrafici
     */
    valida(cf, nome, cognome, dataNascita, sesso) {
        cf = cf.toUpperCase().trim();
        
        // 1. Valida formato
        const formatoCheck = this.validaFormato(cf);
        if (!formatoCheck.valid) {
            return formatoCheck;
        }
        
        // 2. Verifica carattere di controllo
        const cf15 = cf.substring(0, 15);
        const carattereControllo = this.calcolaCarattereControllo(cf15);
        
        if (carattereControllo !== cf[15]) {
            return { 
                valid: false, 
                error: 'Carattere di controllo non valido. Il CF potrebbe contenere errori di battitura.' 
            };
        }
        
        // 3. Calcola CF corretto dai dati forniti
        const cognomeCF = this.calcolaCognome(cognome);
        const nomeCF = this.calcolaNome(nome);
        const annoCF = this.calcolaAnno(dataNascita);
        const meseCF = this.calcolaMese(dataNascita);
        const giornoCF = this.calcolaGiornoSesso(dataNascita, sesso);
        
        const cfCalcolato15 = cognomeCF + nomeCF + annoCF + meseCF + giornoCF;
        const cfCalcolato = cfCalcolato15 + cf.substring(11, 15) + this.calcolaCarattereControllo(cfCalcolato15 + cf.substring(11, 15));
        
        // 4. Confronta primi 11 caratteri (cognome, nome, data, sesso)
        const primi11CF = cf.substring(0, 11);
        const primi11Calcolati = cognomeCF + nomeCF + annoCF + meseCF + giornoCF;
        
        if (primi11CF !== primi11Calcolati) {
            // Estrai dati dal CF per mostrare la discrepanza
            const datiCF = this.estraiDatiDaCF(cf);
            
            let errori = [];
            if (datiCF.anno !== dataNascita.getFullYear()) {
                errori.push(`Anno: CF indica ${datiCF.anno}, inserito ${dataNascita.getFullYear()}`);
            }
            if (datiCF.mese !== dataNascita.getMonth() + 1) {
                errori.push(`Mese: CF indica ${datiCF.mese}, inserito ${dataNascita.getMonth() + 1}`);
            }
            if (datiCF.giorno !== dataNascita.getDate()) {
                errori.push(`Giorno: CF indica ${datiCF.giorno}, inserito ${dataNascita.getDate()}`);
            }
            if (datiCF.sesso !== sesso.toUpperCase()) {
                errori.push(`Sesso: CF indica ${datiCF.sesso}, inserito ${sesso}`);
            }
            
            return { 
                valid: false, 
                error: `Il codice fiscale non corrisponde ai dati inseriti:\n${errori.join('\n')}` 
            };
        }
        
        return { valid: true, message: 'Codice fiscale valido ✓' };
    },

    /**
     * Calcola l'età da una data di nascita
     */
    calcolaEta(dataNascita) {
        const oggi = new Date();
        let eta = oggi.getFullYear() - dataNascita.getFullYear();
        const mese = oggi.getMonth() - dataNascita.getMonth();
        
        if (mese < 0 || (mese === 0 && oggi.getDate() < dataNascita.getDate())) {
            eta--;
        }
        
        return eta;
    },

    /**
     * Verifica se maggiorenne (18+)
     */
    isMaggiorenne(dataNascita) {
        return this.calcolaEta(dataNascita) >= 18;
    }
};

// Export per uso come modulo
if (typeof module !== 'undefined' && module.exports) {
    module.exports = CodiceFiscale;
}
