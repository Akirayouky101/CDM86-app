/**
 * CDM86 - Intro Modal (Vanilla JS)
 * Mostra una volta sola all'utente come funziona la piattaforma.
 * Si riapre solo se l'utente cancella i dati del browser.
 */

(function () {
  'use strict';

  const STORAGE_KEY = 'cdm86_intro_seen';
  const STEP_DURATION = 5000; // ms per step automatico

  const STEPS = [
    {
      id: 1,
      icon: '📣',
      title: 'Parla con Amici e Familiari',
      desc: 'Condividi il tuo link referral personale con chi conosci. Loro si registrano, risparmiano sulle promozioni locali e tu guadagni insieme a loro.',
      color: '#6366f1',
      bg: '#eef2ff',
      figure: 'megaphone'
    },
    {
      id: 2,
      icon: '🔗',
      title: 'Il Tuo Link Referral Personale',
      desc: 'Ogni registrazione tramite il tuo link ti fa guadagnare bonus in Euro diretti. Più persone porti, più crescono i tuoi premi.',
      color: '#8b5cf6',
      bg: '#f5f3ff',
      figure: 'link'
    },
    {
      id: 3,
      icon: '🏪',
      title: 'Porta le Aziende',
      desc: 'Presenta CDM86 ai commercianti e alle imprese locali. Si fanno pubblicità, ricevono nuovi clienti e risparmiano — tu vieni premiato per ogni azienda che porti.',
      color: '#f59e0b',
      bg: '#fffbeb',
      figure: 'business'
    },
    {
      id: 4,
      icon: '🤝',
      title: 'Porta le Associazioni',
      desc: 'Suggerisci CDM86 alle associazioni locali. Danno un servizio utile ai loro soci, si promuovono e guadagnano — e tu vieni premiato per ogni associazione iscritta.',
      color: '#10b981',
      bg: '#ecfdf5',
      figure: 'association'
    },
    {
      id: 5,
      icon: '💰',
      title: 'Bonus in Euro Diretti',
      desc: 'Per ogni referral attivo ricevi bonus in Euro che puoi usare direttamente sulla piattaforma. Più la tua rete cresce, più guadagni in modo continuativo.',
      color: '#059669',
      bg: '#d1fae5',
      figure: 'bonus'
    },
    {
      id: 6,
      icon: '🏆',
      title: 'Cresciamo Insieme',
      desc: 'Accumula punti per sbloccare ulteriori premi in Euro indiretti. Più sei attivo nel passaparola, più sali di livello e più benefici ottieni.',
      color: '#f59e0b',
      bg: '#fef3c7',
      figure: 'trophy'
    },
    {
      id: 7,
      icon: '🌍',
      title: 'Un Mondo di Opportunità',
      desc: 'Amici, famiglie, aziende, associazioni — chiunque porti su CDM86 diventa parte della tua rete. Il tuo passaparola vale e noi ti premiamo per ogni passo.',
      color: '#3b82f6',
      bg: '#eff6ff',
      figure: 'world'
    }
  ];

  // ─── Build HTML ────────────────────────────────────────────────

  function buildFigure(figure, color) {
    switch (figure) {
      case 'megaphone':
        return `<div class="im-megaphone">📣</div>`;

      case 'link':
        return `
          <div class="im-link-scene">
            <div class="im-link-icon">🔗</div>
            <div class="im-link-badge" style="background:${color}">cdm86.com/ref/TUO-CODICE</div>
          </div>`;

      case 'business':
        return `
          <div class="im-biz-scene">
            <div class="im-building-icon">🏪</div>
            <div class="im-coin-stack">
              <div class="im-coin">💰</div>
              <div class="im-coin" style="animation-delay:.3s">🪙</div>
              <div class="im-coin" style="animation-delay:.6s">💰</div>
            </div>
          </div>`;

      case 'association':
        return `
          <div class="im-assoc-scene">
            <div class="im-assoc-icon">🤝</div>
            <div class="im-people">
              <div class="im-person-icon">👤</div>
              <div class="im-arrow-between">→</div>
              <div class="im-person-icon" style="font-size:46px">👥</div>
              <div class="im-arrow-between">→</div>
              <div class="im-person-icon">👤</div>
            </div>
          </div>`;

      case 'bonus':
        return `
          <div class="im-bonus-scene">
            <div class="im-euro-big">💶</div>
            <div class="im-spark">✦</div>
            <div class="im-spark">⭐</div>
            <div class="im-spark">✦</div>
            <div class="im-spark">⭐</div>
          </div>`;

      case 'trophy':
        return `
          <div class="im-trophy-scene">
            <div class="im-trophy-icon">🏆</div>
          </div>`;

      case 'world':
        return `
          <div class="im-people">
            <div class="im-person-icon">🏠</div>
            <div class="im-arrow-between">→</div>
            <div class="im-person-icon" style="font-size:48px">🌍</div>
            <div class="im-arrow-between">→</div>
            <div class="im-person-icon">🏪</div>
          </div>`;

      default:
        return `<div style="font-size:64px">${STEPS.find(s => s.figure === figure)?.icon || '⭐'}</div>`;
    }
  }

  function buildModal() {
    const overlay = document.createElement('div');
    overlay.id = 'cdm86-intro-overlay';
    overlay.className = 'im-overlay';
    overlay.setAttribute('role', 'dialog');
    overlay.setAttribute('aria-modal', 'true');
    overlay.setAttribute('aria-label', 'Come funziona CDM86');

    overlay.innerHTML = `
      <div class="im-modal" id="cdm86-intro-modal">

        <!-- Header -->
        <div class="im-header">
          <div class="im-header-logo">🚀</div>
          <div class="im-header-text">
            <h2>Come funziona CDM86</h2>
            <p>Risparmia, guadagna e fai crescere la tua rete con il <strong>passaparola</strong></p>
          </div>
          <button class="im-skip" id="im-skip-btn" aria-label="Salta introduzione">Salta ✕</button>
        </div>

        <!-- Dots navigation -->
        <div class="im-dots" id="im-dots"></div>

        <!-- Animated stage -->
        <div class="im-stage im-enter" id="im-stage"
             style="--stage-bg: ${STEPS[0].bg}; --stage-color: ${STEPS[0].color}">
          <div class="im-figure" id="im-figure">
            ${buildFigure(STEPS[0].figure, STEPS[0].color)}
          </div>
          <div class="im-step-info">
            <div class="im-step-badge" id="im-step-badge" style="background:${STEPS[0].color}">
              Passo 1 di ${STEPS.length}
            </div>
            <h3 class="im-step-title" id="im-step-title" style="color:${STEPS[0].color}">
              ${STEPS[0].title}
            </h3>
            <p class="im-step-desc" id="im-step-desc">${STEPS[0].desc}</p>
          </div>
        </div>

        <!-- Progress bar -->
        <div class="im-progress-track">
          <div class="im-progress-fill" id="im-progress-fill"
               style="width:0%; background:${STEPS[0].color}"></div>
        </div>

        <!-- Summary chips -->
        <div class="im-summary" id="im-summary"></div>

        <!-- Footer CTA -->
        <div class="im-footer">
          <button class="im-cta-btn" id="im-cta-btn">
            Inizia ora 🚀
          </button>
          <p class="im-note">Puoi rivedere questa guida dal menu del tuo profilo</p>
        </div>

      </div>
    `;

    return overlay;
  }

  // ─── Controller ────────────────────────────────────────────────

  let currentStep = 0;
  let animating = false;
  let autoTimer = null;
  let progressTimer = null;
  let progressStart = null;

  function renderDots() {
    const container = document.getElementById('im-dots');
    if (!container) return;
    container.innerHTML = STEPS.map((s, i) => `
      <button
        class="im-dot ${i === currentStep ? 'active' : i < currentStep ? 'done' : ''}"
        style="--dot-color:${s.color}"
        data-index="${i}"
        aria-label="Step ${i + 1}"
      ></button>
    `).join('');
    container.querySelectorAll('.im-dot').forEach(btn => {
      btn.addEventListener('click', () => goToStep(parseInt(btn.dataset.index)));
    });
  }

  function renderSummary() {
    const container = document.getElementById('im-summary');
    if (!container) return;
    container.innerHTML = STEPS.map((s, i) => `
      <div
        class="im-summary-chip ${i === currentStep ? 'active' : i < currentStep ? 'done' : ''}"
        style="--chip-color:${s.color}; --chip-bg:${s.bg}"
        data-index="${i}"
        role="button"
        tabindex="0"
        aria-label="${s.title}"
      >
        <span class="im-summary-chip-icon">${s.icon}</span>
        <span>${s.title.split(' ').slice(0, 2).join(' ')}</span>
      </div>
    `).join('');
    container.querySelectorAll('.im-summary-chip').forEach(chip => {
      chip.addEventListener('click', () => goToStep(parseInt(chip.dataset.index)));
    });
  }

  function updateStage(step) {
    const stage   = document.getElementById('im-stage');
    const figure  = document.getElementById('im-figure');
    const badge   = document.getElementById('im-step-badge');
    const title   = document.getElementById('im-step-title');
    const desc    = document.getElementById('im-step-desc');
    const fill    = document.getElementById('im-progress-fill');
    const ctaBtn  = document.getElementById('im-cta-btn');
    if (!stage) return;

    stage.style.setProperty('--stage-bg', step.bg);
    stage.style.setProperty('--stage-color', step.color);
    figure.innerHTML = buildFigure(step.figure, step.color);
    badge.textContent = `Passo ${step.id} di ${STEPS.length}`;
    badge.style.background = step.color;
    title.textContent = step.title;
    title.style.color = step.color;
    desc.textContent = step.desc;
    fill.style.background = step.color;
    fill.style.width = '0%';

    // CTA button changes on last step
    if (currentStep === STEPS.length - 1) {
      ctaBtn.textContent = '🚀 Inizia ora!';
    } else {
      ctaBtn.textContent = 'Inizia ora 🚀';
    }
  }

  function animateProgress() {
    clearInterval(progressTimer);
    progressStart = Date.now();
    const fill = document.getElementById('im-progress-fill');
    progressTimer = setInterval(() => {
      if (!fill) return;
      const elapsed = Date.now() - progressStart;
      const pct = Math.min((elapsed / STEP_DURATION) * 100, 100);
      fill.style.width = pct + '%';
    }, 30);
  }

  function goToStep(index) {
    if (animating || index === currentStep) return;
    clearTimeout(autoTimer);
    clearInterval(progressTimer);
    animating = true;

    const stage = document.getElementById('im-stage');
    if (stage) {
      stage.classList.remove('im-enter');
      stage.classList.add('im-exit');
    }

    setTimeout(() => {
      currentStep = index;
      updateStage(STEPS[currentStep]);
      renderDots();
      renderSummary();

      if (stage) {
        stage.classList.remove('im-exit');
        stage.classList.add('im-enter');
      }
      animating = false;
      animateProgress();
      scheduleNext();
    }, 300);
  }

  function advance() {
    goToStep((currentStep + 1) % STEPS.length);
  }

  function scheduleNext() {
    clearTimeout(autoTimer);
    autoTimer = setTimeout(advance, STEP_DURATION);
  }

  function closeModal() {
    const overlay = document.getElementById('cdm86-intro-overlay');
    if (!overlay) return;
    clearTimeout(autoTimer);
    clearInterval(progressTimer);
    overlay.style.animation = 'im-fade-out 0.35s ease forwards';
    setTimeout(() => overlay.remove(), 350);
    // NON salviamo nel localStorage — la modal è su richiesta, non automatica
  }

  // ─── Init ──────────────────────────────────────────────────────

  function init() {
    // La modal è sempre disponibile su richiesta — nessun blocco localStorage

    const overlay = buildModal();
    document.body.appendChild(overlay);

    // Render initial state
    renderDots();
    renderSummary();

    // Close on overlay click
    overlay.addEventListener('click', (e) => {
      if (e.target === overlay) closeModal();
    });

    // Skip button
    document.getElementById('im-skip-btn')
      ?.addEventListener('click', closeModal);

    // CTA button → chiude la modal e apre lapiattaforma.html
    document.getElementById('im-cta-btn')
      ?.addEventListener('click', () => {
        closeModal();
        window.location.href = '/public/lapiattaforma.html';
      });

    // Keyboard: Esc to close, arrows to navigate
    document.addEventListener('keydown', handleKeydown);

    // Start auto-advance + progress
    animateProgress();
    scheduleNext();

    // Add fade-out keyframe dynamically if not present
    if (!document.getElementById('im-fade-out-style')) {
      const style = document.createElement('style');
      style.id = 'im-fade-out-style';
      style.textContent = `@keyframes im-fade-out { from{opacity:1} to{opacity:0} }`;
      document.head.appendChild(style);
    }
  }

  function handleKeydown(e) {
    const overlay = document.getElementById('cdm86-intro-overlay');
    if (!overlay) {
      document.removeEventListener('keydown', handleKeydown);
      return;
    }
    if (e.key === 'Escape') closeModal();
    if (e.key === 'ArrowRight' || e.key === 'ArrowDown') advance();
    if (e.key === 'ArrowLeft'  || e.key === 'ArrowUp')   goToStep(Math.max(0, currentStep - 1));
  }

  // ─── Public API ────────────────────────────────────────────────
  // Permette di riaprire la modale dal profilo utente
  window.CDM86Intro = {
    show: function () {
      const existing = document.getElementById('cdm86-intro-overlay');
      if (existing) existing.remove();
      currentStep = 0;
      animating = false;
      init();
    },
    reset: function () {
      try { localStorage.removeItem(STORAGE_KEY); } catch (e) { /* noop */ }
    }
  };

  // ─── Auto-launch on DOM ready ──────────────────────────────────
  // La modal NON si apre automaticamente — viene aperta solo tramite CDM86Intro.show()
  // (es. dal link "Clicca Qui" in promotions.html)

})();
