/* popup.js - FindWell Core SPA Controller & AI Service Layer
 * Architecture: Login-first gate + Supabase cloud sync for cross-device memory
 */

document.addEventListener('DOMContentLoaded', () => {

  // === SUPABASE CONFIG (loaded from config.js) ===
  const SUPABASE_URL = FINDWELL_CONFIG.SUPABASE_URL;
  const SUPABASE_ANON_KEY = FINDWELL_CONFIG.SUPABASE_ANON_KEY;

  // === LLM API KEYS (loaded from config.js) ===
  const GEMINI_API_KEY = FINDWELL_CONFIG.GEMINI_API_KEY;
  const GROQ_API_KEY = FINDWELL_CONFIG.GROQ_API_KEY;
  const OPENROUTER_API_KEY = FINDWELL_CONFIG.OPENROUTER_API_KEY;

  // === STATE ===
  let currentUser = null;
  let currentToken = null;
  let currentAuthMode = 'login';
  let currentActiveView = 'auth';

  let currentSession = {
    id: crypto.randomUUID(),
    createdAt: new Date().toISOString(),
    page: { title: '', domain: '', url: '', favicon: '' },
    pageContext: null,
    activeGoal: null,
    analysis: null,
    messages: [],
    sources: []
  };

  // === DOM REFS ===
  const views = {
    auth: document.getElementById('view-auth'),
    analyzing: document.getElementById('view-analyzing'),
    analysis: document.getElementById('view-analysis'),
    chat: document.getElementById('view-chat'),
    researching: document.getElementById('view-researching'),
    evidence: document.getElementById('view-evidence'),
    warning: document.getElementById('view-security-warning'),
    context: document.getElementById('view-context'),
    history: document.getElementById('view-history'),
    settings: document.getElementById('view-settings'),
    pdfReady: document.getElementById('view-pdf-ready'),
    error: document.getElementById('view-error')
  };

  const appHeader = document.getElementById('app-header');
  const appBottomNav = document.getElementById('app-bottom-nav');
  const navBtnAnalysis = document.getElementById('nav-btn-analysis');
  const navBtnChat = document.getElementById('nav-btn-chat');
  const navBtnHistory = document.getElementById('nav-btn-history');
  const headerAccountBtn = document.getElementById('header-account-btn');
  const headerContextBtn = document.getElementById('header-context-btn');

  // ============================================================
  // 1. VIEW ROUTING
  // ============================================================
  function showView(viewId) {
    currentActiveView = viewId;
    Object.keys(views).forEach(key => {
      if (views[key]) views[key].classList.remove('active');
    });
    if (views[viewId]) {
      views[viewId].classList.add('active');
      const canvas = views[viewId].querySelector('.content-canvas');
      if (canvas) canvas.scrollTop = 0;
    }

    // Hide bottom nav for auth and transient views
    if (['auth', 'analyzing', 'researching', 'pdfReady', 'error', 'warning'].includes(viewId)) {
      appBottomNav.style.display = 'none';
    } else {
      appBottomNav.style.display = 'flex';
    }

    // Show context btn only when logged in
    if (headerContextBtn) {
      headerContextBtn.style.display = currentUser ? 'flex' : 'none';
    }

    // Highlight active nav
    [navBtnAnalysis, navBtnChat, navBtnHistory].forEach(btn => {
      if (btn) btn.classList.remove('active');
    });
    if (viewId === 'analysis' && navBtnAnalysis) navBtnAnalysis.classList.add('active');
    if (viewId === 'chat' && navBtnChat) navBtnChat.classList.add('active');
    if (viewId === 'history' && navBtnHistory) navBtnHistory.classList.add('active');
  }

  // ============================================================
  // 2. AUTH MODULE (Login-First Gate)
  // ============================================================
  function initAuthView() {
    
    
    const authForm = document.getElementById('findwell-auth-form');

    
    
    if (authForm) authForm.addEventListener('submit', handleAuthSubmit);

    // Password visibility toggles
    const btnTogglePwd = document.getElementById('btn-toggle-pwd');
    const pwdInput = document.getElementById('fw-auth-password');
    if (btnTogglePwd && pwdInput) {
      btnTogglePwd.addEventListener('click', () => {
        const isPwd = pwdInput.type === 'password';
        pwdInput.type = isPwd ? 'text' : 'password';
        btnTogglePwd.querySelector('.material-symbols-outlined').textContent = isPwd ? 'visibility_off' : 'visibility';
      });
    }

    const btnToggleConfirmPwd = document.getElementById('btn-toggle-confirm-pwd');
    const confirmPwdInput = document.getElementById('fw-auth-confirm-password');
    if (btnToggleConfirmPwd && confirmPwdInput) {
      btnToggleConfirmPwd.addEventListener('click', () => {
        const isPwd = confirmPwdInput.type === 'password';
        confirmPwdInput.type = isPwd ? 'text' : 'password';
        btnToggleConfirmPwd.querySelector('.material-symbols-outlined').textContent = isPwd ? 'visibility_off' : 'visibility';
      });
    }
  }

  function toggleAuthTab(mode) {
    currentAuthMode = mode;
    
    
    const submitBtn = document.getElementById('fw-auth-submit-btn');
    const confirmPwdContainer = document.getElementById('fw-confirm-pwd-container');

    if (tabSignIn) {
      tabSignIn.style.background = mode === 'login' ? '#7C3AED' : 'transparent';
      tabSignIn.style.color = mode === 'login' ? 'white' : '#7C3AED';
      tabSignIn.style.border = mode === 'login' ? 'none' : '1px solid #7C3AED';
    }
    if (tabSignUp) {
      tabSignUp.style.background = mode === 'signup' ? '#7C3AED' : 'transparent';
      tabSignUp.style.color = mode === 'signup' ? 'white' : '#7C3AED';
      tabSignUp.style.border = mode === 'signup' ? 'none' : '1px solid #7C3AED';
    }
    if (submitBtn) {
      submitBtn.innerText = mode === 'login' ? 'Sign In to FindWell' : 'Create Account';
    }
    if (confirmPwdContainer) {
      confirmPwdContainer.style.display = mode === 'signup' ? 'block' : 'none';
    }
  }

  function toggleAuthTab(mode) {
    currentAuthMode = mode;
    
    
    const submitBtn = document.getElementById('fw-auth-submit-btn');

    if (tabSignIn) {
      tabSignIn.style.background = mode === 'login' ? '#7C3AED' : 'transparent';
      tabSignIn.style.color = mode === 'login' ? 'white' : '#7C3AED';
      tabSignIn.style.border = mode === 'login' ? 'none' : '1px solid #7C3AED';
    }
    if (tabSignUp) {
      tabSignUp.style.background = mode === 'signup' ? '#7C3AED' : 'transparent';
      tabSignUp.style.color = mode === 'signup' ? 'white' : '#7C3AED';
      tabSignUp.style.border = mode === 'signup' ? 'none' : '1px solid #7C3AED';
    }
    if (submitBtn) {
      submitBtn.innerText = mode === 'login' ? 'Sign In to FindWell' : 'Create Account';
    }
  }

  async function handleAuthSubmit(e) {
    e.preventDefault();
    const email = document.getElementById('fw-auth-email').value.trim();
    const password = document.getElementById('fw-auth-password').value.trim();
    const statusDiv = document.getElementById('fw-auth-status');
    const submitBtn = document.getElementById('fw-auth-submit-btn');

    if (!email || !password) {
      if (statusDiv) { statusDiv.style.color = '#EF4444'; statusDiv.innerText = 'Please enter email and password'; }
      return;
    }

    if (statusDiv) { statusDiv.style.color = '#7C3AED'; statusDiv.innerText = 'Connecting to FindWell Cloud...'; }
    if (submitBtn) submitBtn.disabled = true;

    const endpoint = currentAuthMode === 'login' ? `${SUPABASE_URL}/auth/v1/token?grant_type=password` : `${SUPABASE_URL}/auth/v1/signup`;

    try {
      const res = await fetch(endpoint, {
        method: 'POST',
        headers: { 'apikey': SUPABASE_ANON_KEY, 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password })
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error_description || data.msg || 'Authentication failed');

      currentUser = data.user;
      currentToken = data.access_token;
      chrome.storage.local.set({ findwell_session: { user: currentUser, access_token: currentToken } });

      if (statusDiv) { statusDiv.style.color = '#10B981'; statusDiv.innerText = '✓ Signed in successfully!'; }

      // Update settings email display
      const settingsEmail = document.getElementById('settings-user-email');
      if (settingsEmail) settingsEmail.innerText = currentUser.email || 'User';

      setTimeout(() => {
        onAuthSuccess();
      }, 500);
    } catch (err) {
      if (statusDiv) { statusDiv.style.color = '#EF4444'; statusDiv.innerText = `Error: ${err.message}`; }
    } finally {
      if (submitBtn) submitBtn.disabled = false;
    }
  }

  function onAuthSuccess() {
    // After login, start the main app flow
    chrome.storage.local.get(['pendingSelectionText', 'pendingSourceUrl'], (res) => {
      if (res.pendingSelectionText) {
        chrome.storage.local.remove(['pendingSelectionText', 'pendingSourceUrl']);
        initPageAnalysis(res.pendingSelectionText);
      } else {
        initPageAnalysis();
      }
    });
  }

  function handleLogout() {
    chrome.storage.local.remove(['findwell_session']);
    currentUser = null;
    currentToken = null;
    currentSession = {
      id: crypto.randomUUID(),
      createdAt: new Date().toISOString(),
      page: { title: '', domain: '', url: '', favicon: '' },
      pageContext: null, analysis: null, activeGoal: null, messages: [], sources: []
    };
    showView('auth');
    // Reset auth form
    const authForm = document.getElementById('findwell-auth-form');
    const statusDiv = document.getElementById('fw-auth-status');
    if (authForm) { authForm.reset(); authForm.style.display = 'flex'; }
    if (statusDiv) statusDiv.innerHTML = '';
  }

  // ============================================================
  // 3. SUPABASE CLOUD SYNC SERVICE
  // ============================================================
  function supabaseHeaders(preferUpsert = false) {
    return {
      'apikey': SUPABASE_ANON_KEY,
      'Authorization': `Bearer ${currentToken}`,
      'Content-Type': 'application/json',
      'Prefer': preferUpsert ? 'resolution=merge-duplicates,return=representation' : 'return=representation'
    };
  }

  async function syncSessionToCloud() {
    if (!currentUser || !currentToken) return;
    try {
      const payload = {
        user_id: currentUser.id,
        session_key: currentSession.id,
        page_title: currentSession.page.title || null,
        page_domain: currentSession.page.domain || null,
        page_url: currentSession.page.url || null,
        page_favicon: currentSession.page.favicon || null,
        analysis: currentSession.analysis || null,
        messages: currentSession.messages || [],
        sources: currentSession.sources || [],
        active_goal: currentSession.activeGoal || null,
        updated_at: new Date().toISOString()
      };

      // Upsert by session_key
      await fetch(`${SUPABASE_URL}/rest/v1/extension_sessions?on_conflict=user_id,session_key`, {
        method: 'POST',
        headers: supabaseHeaders(true),
        body: JSON.stringify(payload)
      });
    } catch (err) {
      console.warn('Cloud sync failed (will retry):', err);
    }
  }

  async function saveChatMessageToCloud(role, content) {
    if (!currentUser || !currentToken) return;
    try {
      // Find or create a project for this domain
      const projectId = await getOrCreateProject();
      if (!projectId) return;

      await fetch(`${SUPABASE_URL}/rest/v1/chat_messages`, {
        method: 'POST',
        headers: supabaseHeaders(),
        body: JSON.stringify({
          project_id: projectId,
          user_id: currentUser.id,
          role: role === 'ai' ? 'assistant' : role,
          content: content,
          model: currentSelectedModel || '4-LLM Ensemble'
        })
      });
    } catch (err) {
      console.warn('Failed to save chat message to cloud:', err);
    }
  }

  let _cachedProjectId = null;
  async function getOrCreateProject() {
    if (_cachedProjectId) return _cachedProjectId;
    if (!currentUser || !currentToken) return null;

    const domain = currentSession.page.domain || 'general';
    const topic = currentSession.page.title || domain;

    try {
      // Check for existing project with this domain
      const searchRes = await fetch(
        `${SUPABASE_URL}/rest/v1/projects?user_id=eq.${currentUser.id}&domain=eq.${encodeURIComponent(domain)}&select=id&limit=1`,
        { headers: supabaseHeaders() }
      );
      const existing = await searchRes.json();
      if (existing && existing.length > 0) {
        _cachedProjectId = existing[0].id;
        return _cachedProjectId;
      }

      // Create new project
      const createRes = await fetch(`${SUPABASE_URL}/rest/v1/projects`, {
        method: 'POST',
        headers: supabaseHeaders(),
        body: JSON.stringify({
          user_id: currentUser.id,
          topic: topic,
          domain: domain,
          current_stage: 0
        })
      });
      const created = await createRes.json();
      if (created && created.length > 0) {
        _cachedProjectId = created[0].id;
      }
      return _cachedProjectId;
    } catch (err) {
      console.warn('Project sync failed:', err);
      return null;
    }
  }

  async function loadCloudHistory() {
    if (!currentUser || !currentToken) return [];
    try {
      const res = await fetch(
        `${SUPABASE_URL}/rest/v1/extension_sessions?user_id=eq.${currentUser.id}&order=updated_at.desc&limit=30`,
        { headers: supabaseHeaders() }
      );
      if (res.ok) {
        const sessions = await res.json();
        return sessions.map(s => ({
          id: s.session_key,
          createdAt: s.created_at,
          page: { title: s.page_title || '', domain: s.page_domain || '', url: s.page_url || '', favicon: s.page_favicon || '' },
          pageContext: null,
          analysis: s.analysis,
          activeGoal: s.active_goal,
          messages: s.messages || [],
          sources: s.sources || []
        }));
      }
    } catch (err) {
      console.warn('Failed to load cloud history:', err);
    }
    return [];
  }

  // ============================================================
  // 4. MULTI-LLM ENGINE
  // ============================================================
  let currentSelectedModel = '4-LLM Ensemble';

  function getSelectedModelDisplayName() {
    const checkedRadio = document.querySelector('input[name="settings_model"]:checked');
    if (checkedRadio) {
      currentSelectedModel = checkedRadio.value;
    }
    if (currentSelectedModel === 'gemini-2.0-flash') return 'Google Gemini (2.0 Flash)';
    if (currentSelectedModel === 'llama-3.1-8b-instant') return 'Groq (Llama 3.1 8B)';
    if (currentSelectedModel === 'openrouter/auto') return 'OpenRouter Auto';
    return '4-LLM Ensemble';
  }

  // Load stored model preference
  chrome.storage.local.get(['findwell_selected_model'], (res) => {
    if (res.findwell_selected_model) {
      currentSelectedModel = res.findwell_selected_model;
      updateModelSelectionUI();
    }
  });

  function updateModelSelectionUI() {
    const radios = document.querySelectorAll('input[name="settings_model"]');
    radios.forEach(r => {
      r.checked = (r.value === currentSelectedModel);
    });
    const subText = document.getElementById('settings-model-subtext');
    if (subText) subText.innerText = `Active Model: ${getSelectedModelDisplayName()}`;
  }

  function initModelSelectionHandlers() {
    const radios = document.querySelectorAll('input[name="settings_model"]');
    radios.forEach(r => {
      r.addEventListener('change', (e) => {
        if (e.target.checked) {
          currentSelectedModel = e.target.value;
          chrome.storage.local.set({ findwell_selected_model: currentSelectedModel });
          const subText = document.getElementById('settings-model-subtext');
          if (subText) subText.innerText = `Active Model: ${currentSelectedModel}`;
        }
      });
    });
  }

  function isGibberishText(text) {
    if (!text || text.length < 10) return false;
    let scriptCount = 0;
    if (/[\u0400-\u04FF]/.test(text)) scriptCount++; // Cyrillic
    if (/[\u0900-\u097F]/.test(text)) scriptCount++; // Devanagari
    if (/[\u0590-\u05FF]/.test(text)) scriptCount++; // Hebrew
    if (/[\u0E00-\u0E7F]/.test(text)) scriptCount++; // Thai
    if (/[\u4E00-\u9FFF]/.test(text)) scriptCount++; // CJK
    if (/[\u0D00-\u0D7F]/.test(text)) scriptCount++; // Malayalam
    if (/[\uAC00-\uD7AF]/.test(text)) scriptCount++; // Korean

    if (scriptCount >= 2) return true;
    if (/(\$\w+|\w+_\w{4,}|\b\w+<[A-Z]\w+)/.test(text) && scriptCount >= 1) return true;
    return false;
  }

  async function fetchMultiLLM(requestBody) {
    let promptText = '';
    if (requestBody && requestBody.contents && requestBody.contents[0] && requestBody.contents[0].parts && requestBody.contents[0].parts[0]) {
      promptText = requestBody.contents[0].parts[0].text;
    }

    const callGemini = async () => {
      const geminiModels = ['gemini-2.0-flash', 'gemini-1.5-flash', 'gemini-flash-latest'];
      for (const model of geminiModels) {
        try {
          const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${GEMINI_API_KEY}`;
          const res = await fetch(url, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(requestBody)
          });
          if (res.ok) {
            const data = await res.json();
            if (data.candidates && data.candidates.length > 0 && data.candidates[0].content && data.candidates[0].content.parts && data.candidates[0].content.parts.length > 0) {
              const outText = data.candidates[0].content.parts[0].text.trim();
              if (!isGibberishText(outText)) return outText;
            }
          }
        } catch (err) { }
      }
      throw new Error('Gemini API call failed');
    };

    const callGroq = async () => {
      const groqRes = await fetch('https://api.groq.com/openai/v1/chat/completions', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${GROQ_API_KEY}` },
        body: JSON.stringify({ model: 'llama-3.1-8b-instant', messages: [{ role: 'user', content: promptText || 'Analyze' }], temperature: 0.2 })
      });
      if (groqRes.ok) {
        const groqData = await groqRes.json();
        if (groqData.choices && groqData.choices[0] && groqData.choices[0].message) {
          const outText = groqData.choices[0].message.content.trim();
          if (!isGibberishText(outText)) return outText;
        }
      }
      throw new Error('Groq API call failed');
    };

    const callOpenRouter = async () => {
      const orRes = await fetch('https://openrouter.ai/api/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${OPENROUTER_API_KEY}`,
          'HTTP-Referer': 'https://findwell.ai',
          'X-Title': 'FindWell AI Assistant'
        },
        body: JSON.stringify({ model: 'openai/gpt-4o-mini', messages: [{ role: 'user', content: promptText || 'Analyze' }], max_tokens: 500, temperature: 0.2 })
      });
      if (orRes.ok) {
        const orData = await orRes.json();
        if (orData.choices && orData.choices[0] && orData.choices[0].message) {
          const outText = orData.choices[0].message.content.trim();
          if (!isGibberishText(outText)) return outText;
        }
      }
      throw new Error('OpenRouter API call failed');
    };

    // Route based on user selected model preference with smart fallback
    let providersChain = [];
    if (currentSelectedModel === 'gemini-2.0-flash') {
      providersChain = [callGroq, callGemini, callOpenRouter];
    } else if (currentSelectedModel === 'llama-3.1-8b-instant') {
      providersChain = [callGroq, callGemini, callOpenRouter];
    } else if (currentSelectedModel === 'openrouter/auto') {
      providersChain = [callOpenRouter, callGemini, callGroq];
    } else {
      // Default '4-LLM Ensemble'
      providersChain = [callGroq, callGemini, callOpenRouter];
    }

    let lastErr = null;
    for (const providerFn of providersChain) {
      try {
        const resText = await providerFn();
        if (resText && !isGibberishText(resText)) return resText;
      } catch (err) {
        lastErr = err;
      }
    }

    throw lastErr || new Error('All LLM providers failed');
  }

  async function fetchGeminiAPI(requestBody) {
    return await fetchMultiLLM(requestBody);
  }

// Helper for safe Chrome messaging that clears lastError & auto-injects content script if missing
  async function safeSendMessageToTab(tabId, message) {
    return new Promise((resolve) => {
      chrome.tabs.sendMessage(tabId, message, (response) => {
        const lastErr = chrome.runtime.lastError; // Clear lastError immediately
        if (!lastErr && response) {
          resolve({ success: true, data: response });
          return;
        }

        // Try injecting content script dynamically if missing
        if (chrome.scripting && typeof chrome.scripting.executeScript === 'function') {
          chrome.scripting.executeScript(
            { target: { tabId: tabId }, files: ['content.js'] },
            () => {
              const injectErr = chrome.runtime.lastError; // Clear lastError
              if (injectErr) {
                resolve({ success: false, error: lastErr?.message || injectErr?.message });
                return;
              }
              // Retry sending message after script injection
              chrome.tabs.sendMessage(tabId, message, (retryResponse) => {
                const retryErr = chrome.runtime.lastError; // Clear lastError
                if (!retryErr && retryResponse) {
                  resolve({ success: true, data: retryResponse });
                } else {
                  resolve({ success: false, error: retryErr?.message || 'NO_RESPONSE' });
                }
              });
            }
          );
        } else {
          resolve({ success: false, error: lastErr?.message || 'NO_RESPONSE' });
        }
      });
    });
  }

  // ============================================================
  // 5. PAGE CONTEXT & ANALYSIS SERVICE
  // ============================================================
  async function capturePageContext() {
    return new Promise((resolve) => {
      chrome.tabs.query({ active: true, currentWindow: true }, async (tabs) => {
        const queryErr = chrome.runtime.lastError; // Clear lastError
        if (!tabs || tabs.length === 0) {
          resolve({
            title: 'FindWell AI',
            domain: 'findwell.ai',
            url: '',
            favicon: '',
            content: 'No active browser tab found.',
            navigationItems: [], interactiveElements: [], forms: [], pageSections: [],
            capturedAt: new Date().toISOString()
          });
          return;
        }
        const activeTab = tabs[0];
        const url = activeTab.url || '';

        if (!url || url.startsWith('chrome://') || url.startsWith('chrome-extension://') || url.startsWith('edge://') || url.startsWith('about:') || url.startsWith('https://chrome.google.com/webstore')) {
          resolve({
            title: activeTab.title || 'Browser Page',
            domain: extractDomain(url) || 'browser',
            url: url,
            favicon: activeTab.favIconUrl || '',
            content: 'System or internal browser page. Content extraction skipped.',
            navigationItems: [], interactiveElements: [], forms: [], pageSections: [],
            capturedAt: new Date().toISOString()
          });
          return;
        }

        const res = await safeSendMessageToTab(activeTab.id, { action: 'getPageMetadata' });
        if (res.success && res.data) {
          resolve(res.data);
        } else {
          resolve({
            title: activeTab.title || url,
            domain: extractDomain(url),
            url: url,
            favicon: activeTab.favIconUrl || '',
            content: 'Page content unavailable for deep extraction.',
            navigationItems: [], interactiveElements: [], forms: [], pageSections: [],
            capturedAt: new Date().toISOString()
          });
        }
      });
    });
  }

  function extractDomain(url) {
    try { return new URL(url).hostname; } catch (e) { return url; }
  }

  async function initPageAnalysis(focusedSelection = null) {
    showView('analyzing');
    resetAnalyzingAnimation();
    _cachedProjectId = null; // Reset project cache for new page

    try {
      animateStep(1);
      const pageContext = await capturePageContext();
      currentSession.pageContext = pageContext;
      currentSession.page = {
        title: pageContext.title,
        domain: pageContext.domain,
        url: pageContext.url,
        favicon: pageContext.favicon
      };

      if (detectPromptInjection(pageContext.content)) { showView('warning'); return; }

      animateStep(2); await delay(300);
      animateStep(3); await delay(300);
      animateStep(4);

      const analysisResult = await runAnalysisProvider(pageContext, focusedSelection);
      currentSession.analysis = analysisResult;

      animateStep(5); await delay(200);

      renderAnalysisDashboard(analysisResult, pageContext);
      showView('analysis');

      // Sync to cloud
      syncSessionToCloud();
    } catch (err) {
      console.error('Page Analysis Error:', err);
      showView('error');
    }
  }

  function detectPromptInjection(content) {
    if (!content) return false;
    const lower = content.toLowerCase();
    return ['ignore previous instructions', 'system prompt:', 'you are now a bypass agent', 'developer mode enabled']
      .some(term => lower.includes(term));
  }

  async function runAnalysisProvider(context, focusedSelection) {
    try { return await callGeminiForAnalysis(context, focusedSelection); }
    catch (e) { console.warn('API failed, using mock:', e); return getMockAnalysis(context, focusedSelection); }
  }

  function parseJsonFromLLM(text) {
    if (!text || typeof text !== 'string') throw new Error('Empty LLM response');
    let cleaned = text.trim().replace(/^```(?:json)?\s*/i, '').replace(/\s*```$/i, '').trim();
    try { return JSON.parse(cleaned); } catch (e) { /* continue */ }

    const firstBrace = cleaned.indexOf('{');
    if (firstBrace !== -1) {
      let depth = 0, inString = false, escape = false;
      for (let i = firstBrace; i < cleaned.length; i++) {
        const c = cleaned[i];
        if (escape) { escape = false; continue; }
        if (c === '\\' && inString) { escape = true; continue; }
        if (c === '"') { inString = !inString; continue; }
        if (!inString) {
          if (c === '{') depth++;
          else if (c === '}') { depth--; if (depth === 0) { try { return JSON.parse(cleaned.slice(firstBrace, i + 1)); } catch (err) { /* continue */ } } }
        }
      }
    }
    const m = cleaned.match(/\{[\s\S]*\}/);
    if (m) return JSON.parse(m[0]);
    throw new Error('FAILED_JSON_PARSE');
  }

  async function callGeminiForAnalysis(context, focusedSelection) {
    const title = context?.title || 'Current Webpage';
    const domain = context?.domain || '';
    const url = context?.url || '';
    const contentSnippet = (context?.content && typeof context.content === 'string') ? context.content.substring(0, 3000) : 'No text.';
    const navSnippet = (context?.navigationItems?.length > 0) ? context.navigationItems.map(n => n.text).join(', ') : 'Standard navigation';

    const prompt = `You are FindWell, an AI guide to the web. Analyze this webpage context and return a JSON object ONLY. Do NOT wrap in markdown code fences.
Title: ${title}
Domain: ${domain}
URL: ${url}
Navigation Elements: ${navSnippet}
${focusedSelection ? `Focused Selection: ${focusedSelection}\n` : ''}
Content Snippet: ${contentSnippet}

Return ONLY a valid JSON object with this exact schema:
{
  "summary": "Concise 2-3 sentence overview.",
  "importantSections": [{"name": "...", "desc": "..."}],
  "whatYouCanDo": ["...", "...", "..."],
  "keyInsights": [{"num": "01", "title": "...", "desc": "..."}],
  "potentialDifficulties": ["..."],
  "recommendedNextStep": "...",
  "pageCategory": "coding|academic|design|commerce|travel|documentation|general"
}`;

    const rawText = await fetchGeminiAPI({
      contents: [{ role: 'user', parts: [{ text: prompt }] }],
      generationConfig: { temperature: 0.2, maxOutputTokens: 1200, responseMimeType: 'application/json' }
    });
    return parseJsonFromLLM(rawText);
  }

  function getMockAnalysis(context) {
    const title = context?.title || 'Webpage';
    const domain = context?.domain || 'website.com';
    return {
      summary: `This page on ${domain} ("${title}") provides structured information. FindWell has analyzed the structure.`,
      importantSections: [{ name: 'Main Content', desc: 'Core documentation' }, { name: 'Navigation', desc: 'Key links' }],
      whatYouCanDo: [`Understand concepts on ${domain}`, 'Learn step-by-step with guides', 'Find settings or options'],
      keyInsights: [{ num: '01', title: 'Overview', desc: `About ${title}.` }, { num: '02', title: 'Capabilities', desc: 'Available tools.' }],
      potentialDifficulties: ['Requires basic familiarity with the topic'],
      recommendedNextStep: `Select a goal card below or ask FindWell a question about "${title}".`,
      pageCategory: 'general'
    };
  }

  // ============================================================
  // 6. ANALYSIS DASHBOARD RENDERING
  // ============================================================
  function renderAnalysisDashboard(analysis, pageContext) {
    document.getElementById('analysis-page-title').textContent = currentSession.page.title;
    document.getElementById('analysis-page-domain').textContent = currentSession.page.domain;

    const favImg = document.getElementById('analysis-page-favicon');
    if (currentSession.page.favicon) { favImg.src = currentSession.page.favicon; favImg.style.display = 'block'; }
    else { favImg.style.display = 'none'; }

    document.getElementById('analysis-summary-text').textContent = analysis.summary || '';

    // Sections
    const sectionsList = document.getElementById('analysis-sections-list');
    sectionsList.innerHTML = '';
    const sections = analysis.importantSections || [];
    if (sections.length === 0 && pageContext?.navigationItems?.length > 0) {
      pageContext.navigationItems.slice(0, 4).forEach(nav => sections.push({ name: nav.text, desc: 'Navigation section' }));
    }
    sections.forEach(sec => {
      const item = document.createElement('div');
      item.className = 'nav-guide-item';
      item.innerHTML = `<div><span class="text-label-md" style="color: var(--primary); display: block;">${escapeHtml(sec.name)}</span><span class="text-body-sm" style="color: var(--text-muted);">${escapeHtml(sec.desc)}</span></div><span class="material-symbols-outlined" style="font-size: 16px; color: var(--findwell-green);">near_me</span>`;
      item.addEventListener('click', () => highlightOnPage(sec.name));
      sectionsList.appendChild(item);
    });

    // Capabilities
    const capList = document.getElementById('analysis-capabilities-list');
    capList.innerHTML = (analysis.whatYouCanDo || []).map(c =>
      `<div style="display: flex; align-items: flex-start; gap: 6px; font-size: 12px; color: var(--on-surface);"><span class="material-symbols-outlined" style="font-size: 16px; color: var(--primary);">check_circle</span> <span>${escapeHtml(c)}</span></div>`
    ).join('');

    // Insights
    const insightsList = document.getElementById('analysis-insights-list');
    insightsList.innerHTML = '';
    (analysis.keyInsights || []).forEach(item => {
      const card = document.createElement('div');
      card.className = 'insight-card';
      card.innerHTML = `<span class="insight-number">${item.num}</span><div><span class="text-label-md" style="color: var(--on-surface); display: block; margin-bottom: 2px;">${escapeHtml(item.title)}</span><p class="text-body-sm" style="color: var(--on-surface-variant); margin: 0;">${escapeHtml(item.desc)}</p></div>`;
      insightsList.appendChild(card);
    });

    // Difficulties
    const diffList = document.getElementById('analysis-difficulties-list');
    if (diffList) {
      diffList.innerHTML = (analysis.potentialDifficulties || []).map(d =>
        `<div style="display: flex; align-items: flex-start; gap: 6px; font-size: 12px; color: #92400e;"><span class="material-symbols-outlined" style="font-size: 16px; color: #d97706;">warning</span> <span>${escapeHtml(d)}</span></div>`
      ).join('');
    }

    // Recommendation
    const recText = document.getElementById('analysis-recommendation-text');
    if (recText) recText.textContent = analysis.recommendedNextStep || '';
  }

function highlightOnPage(text) {
    chrome.tabs.query({ active: true, currentWindow: true }, async (tabs) => {
      const qErr = chrome.runtime.lastError; // Clear lastError
      if (tabs && tabs[0]) {
        const res = await safeSendMessageToTab(tabs[0].id, { action: 'highlightElement', text: text });
        if (res.success && res.data && res.data.found) {
          appendChatMessage('ai', `📍 Highlighted **"${text}"** on the webpage!`);
          showView('chat');
        } else {
          submitChatMessage(`Where is ${text} on this page?`);
        }
      }
    });
  }

  // Animation helpers
  function resetAnalyzingAnimation() {
    for (let i = 1; i <= 5; i++) {
      const step = document.getElementById(`ana-step-${i}`);
      const icon = document.getElementById(`ana-icon-${i}`);
      if (step && icon) { step.style.opacity = '0.4'; icon.className = 'timeline-step-icon upcoming'; icon.innerHTML = ''; }
    }
  }

  function animateStep(stepNum) {
    for (let i = 1; i < stepNum; i++) {
      const step = document.getElementById(`ana-step-${i}`);
      const icon = document.getElementById(`ana-icon-${i}`);
      if (step && icon) { step.style.opacity = '1'; icon.className = 'timeline-step-icon done'; icon.innerHTML = '<span class="material-symbols-outlined" style="font-size: 14px;">check</span>'; }
    }
    const curr = document.getElementById(`ana-step-${stepNum}`);
    const currIcon = document.getElementById(`ana-icon-${stepNum}`);
    if (curr && currIcon) { curr.style.opacity = '1'; currIcon.className = 'timeline-step-icon active'; currIcon.innerHTML = '<div style="width: 8px; height: 8px; border-radius: 50%; background-color: white;"></div>'; }
  }

  // === CROSS-DEVICE SUPABASE MEMORY SYNC ===
  async function fetchCloudMemories() {
    if (!currentUser || !currentUser.id) return [];
    try {
      const url = `${SUPABASE_URL}/rest/v1/extension_sessions?user_id=eq.${currentUser.id}&session_key=eq.user_memories&select=messages`;
      const res = await fetch(url, {
        headers: {
          'apikey': SUPABASE_ANON_KEY,
          'Authorization': `Bearer ${currentToken || SUPABASE_ANON_KEY}`
        }
      });
      if (res.ok) {
        const data = await res.json();
        if (data && data.length > 0 && data[0].messages) {
          const cloudMems = data[0].messages.map(item => item.content).filter(Boolean);
          chrome.storage.local.get(['user_memories'], (localRes) => {
            const localMems = localRes.user_memories || [];
            const merged = Array.from(new Set([...cloudMems, ...localMems]));
            chrome.storage.local.set({ user_memories: merged });
          });
          return cloudMems;
        }
      }
    } catch (err) {
      console.warn('Failed to fetch cloud memories:', err);
    }
    return [];
  }

  async function saveUserMemoryToSupabase(fact) {
    if (!currentUser || !currentUser.id) return;
    try {
      const getUrl = `${SUPABASE_URL}/rest/v1/extension_sessions?user_id=eq.${currentUser.id}&session_key=eq.user_memories&select=messages`;
      const getRes = await fetch(getUrl, {
        headers: { 'apikey': SUPABASE_ANON_KEY, 'Authorization': `Bearer ${currentToken || SUPABASE_ANON_KEY}` }
      });
      let msgs = [];
      if (getRes.ok) {
        const existing = await getRes.json();
        if (existing && existing.length > 0 && existing[0].messages) {
          msgs = existing[0].messages;
        }
      }
      msgs.push({ role: 'user', content: fact });

      await fetch(`${SUPABASE_URL}/rest/v1/extension_sessions?on_conflict=user_id,session_key`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'apikey': SUPABASE_ANON_KEY,
          'Authorization': `Bearer ${currentToken || SUPABASE_ANON_KEY}`,
          'Prefer': 'resolution=merge-duplicates,return=representation'
        },
        body: JSON.stringify({
          user_id: currentUser.id,
          session_key: 'user_memories',
          page_title: 'User Persistent Memories',
          page_domain: 'findwell.ai',
          page_url: 'https://findwell.ai/memories',
          messages: msgs,
          updated_at: new Date().toISOString()
        })
      });
    } catch (e) {
      console.warn('Error saving memory to Supabase:', e);
    }
  }

  async function getMemoryContextString() {
    const cloudMems = await fetchCloudMemories();
    return new Promise((resolve) => {
      chrome.storage.local.get(['user_memories'], (res) => {
        let mems = Array.from(new Set([...(res.user_memories || []), ...cloudMems]));
        if (mems.length === 0) {
          resolve('None saved yet.');
        } else {
          resolve(mems.map(m => '- ' + m).join('\n'));
        }
      });
    });
  }

  // ============================================================
  // 7. CHAT SERVICE
  // ============================================================
  const chatInput = document.getElementById('chat-input-field');
  const chatSendBtn = document.getElementById('chat-send-btn');
  const chatStream = document.getElementById('chat-stream-list');

  if (chatSendBtn) chatSendBtn.addEventListener('click', handleUserSendMessage);
  if (chatInput) chatInput.addEventListener('keydown', (e) => { if (e.key === 'Enter') handleUserSendMessage(); });

  document.querySelectorAll('#chat-suggestions-chips .suggestion-chip').forEach(chip => {
    chip.addEventListener('click', () => {
      const question = chip.getAttribute('data-question');
      if (question === 'Create Research Brief') { generatePdfReport(); }
      else { submitChatMessage(question); }
    });
  });

  function handleUserSendMessage() {
    const text = chatInput.value.trim();
    if (!text) return;
    chatInput.value = '';
    submitChatMessage(text);
  }

  async function submitChatMessage(questionText) {
    if (!questionText || !questionText.trim()) return;
    const cleanQuery = questionText.trim();

    // Auto-detect "remember" / memory directives (handles typos like "remeber", "rember", "note", "my name is", etc.)
    const isMemoryCmd = /(remember|remeber|rember|keep in mind|note that|my name is|my .* is|save this page|remember this page)/i.test(cleanQuery);
    if (isMemoryCmd) {
      let fact = cleanQuery;
      const lowerQuery = cleanQuery.toLowerCase();

      // If user asks to remember "this page", "this site", "this article", "page details", etc.
      if (lowerQuery.includes('page') || lowerQuery.includes('site') || lowerQuery.includes('article') || lowerQuery.includes('url') || (lowerQuery.includes('this') && !lowerQuery.includes('name'))) {
        const ctx = currentSession.pageContext || {};
        const pageTitle = ctx.title || currentSession.page?.title || 'Webpage';
        const pageUrl = ctx.url || currentSession.page?.url || '';
        const pageSummary = currentSession.analysis?.summary || (ctx.content && typeof ctx.content === 'string' ? ctx.content.substring(0, 300) : '');
        
        fact = `Page "${pageTitle}" (${pageUrl})${pageSummary ? `: ${pageSummary}` : ''}`;
      } else if (/^(remember|remeber|rember)\s*/i.test(cleanQuery)) {
        fact = cleanQuery.replace(/^(remember|remeber|rember)\s*(that|my|is|:)*\s*/i, '').trim();
        if (fact.length > 0) {
          fact = fact.charAt(0).toUpperCase() + fact.slice(1);
        }
      }

      if (fact && fact.length > 3) {
        chrome.storage.local.get(['user_memories'], (res) => {
          const mems = res.user_memories || [];
          if (!mems.includes(fact)) mems.unshift(fact);
          chrome.storage.local.set({ user_memories: mems });
        });
        if (currentUser && currentUser.id) {
          saveUserMemoryToSupabase(fact);
        }
      }
    }
    appendChatMessage('user', cleanQuery);
    currentSession.messages.push({ role: 'user', content: cleanQuery, timestamp: new Date().toISOString() });
    saveChatMessageToCloud('user', cleanQuery);

    const thinkingId = appendChatThinking();

    try {
      let aiAnswer = '';
      try { aiAnswer = await callGeminiForChat(cleanQuery); }
      catch (apiErr) { console.warn('API failed, using fallback:', apiErr); aiAnswer = getMockChatAnswer(cleanQuery); }

      removeChatThinking(thinkingId);
      appendChatMessage('ai', aiAnswer);
      currentSession.messages.push({ role: 'ai', content: aiAnswer, timestamp: new Date().toISOString() });
      saveChatMessageToCloud('assistant', aiAnswer);

      // Video recommendations
      if (shouldAttachVideos(cleanQuery)) {
        const videos = FindWellProviders.VideoProvider.getVideos(cleanQuery, currentSession.pageContext);
        appendVideoCards(videos);
      }

      // Resource recommendations
      if (shouldAttachResources(cleanQuery)) {
        const cat = currentSession.analysis?.pageCategory || 'general';
        const resources = FindWellProviders.ResourceProvider.getResources(cat, cleanQuery);
        appendResourceCards(resources);
      }

      // Save to local + cloud
      saveSessionToHistory();
      syncSessionToCloud();
    } catch (e) {
      console.error('Chat error:', e);
      removeChatThinking(thinkingId);
      const fallback = getMockChatAnswer(cleanQuery);
      appendChatMessage('ai', fallback);
      currentSession.messages.push({ role: 'ai', content: fallback, timestamp: new Date().toISOString() });
    }
  }

  function shouldAttachVideos(q) {
    const l = q.toLowerCase();
    return l.includes('learn') || l.includes('tutorial') || l.includes('video') || l.includes('how to') || l.includes('guide') || l.includes('start');
  }

  function shouldAttachResources(q) {
    const l = q.toLowerCase();
    return l.includes('resource') || l.includes('doc') || l.includes('alternative') || l.includes('link') || l.includes('where to') || l.includes('learn');
  }

  async function callGeminiForChat(question) {
    const ctx = currentSession.pageContext || {};
    const pageTitle = ctx.title || currentSession.page.title || 'Current Webpage';
    const pageDomain = ctx.domain || currentSession.page.domain || '';
    const pageUrl = ctx.url || currentSession.page.url || '';
    const pageContent = (ctx.content && typeof ctx.content === 'string') ? ctx.content.substring(0, 4000) : (currentSession.analysis ? JSON.stringify(currentSession.analysis) : 'No content.');
    const recentHistory = currentSession.messages.slice(-6).map(m => `${m.role === 'user' ? 'User' : 'Assistant'}: ${m.content}`).join('\n');
    const memStr = await getMemoryContextString();

    const systemContext = `You are FindWell, an intelligent AI guide to the web with persistent long-term memory.
The user is viewing: "${pageTitle}" (${pageDomain}) [${pageUrl}].

PERSISTENT USER MEMORY & STORED FACTS:
${memStr}

CRITICAL MEMORY DIRECTIVES:
1. You HAVE long-term memory enabled. Use the stored facts above when relevant to answer user questions.
2. When the user asks you to remember something (e.g. "remember my friend's name is Vinay"), acknowledge warmly that you have stored it for future conversations.
3. If asked about a personal fact (such as a name or preference) that is NOT in the stored memories list above, state politely that you don't have that saved yet and invite them to share it. Do NOT lecture or give meta disclaimers.

Extracted Page Content:
${pageContent}

Recent Conversation History:
${recentHistory}

Instructions:
1. Provide a direct, helpful, concise answer tailored to this specific webpage or question.
2. Use bold (**text**) for important terms.`;

    return await fetchGeminiAPI({
      contents: [{ role: 'user', parts: [{ text: `${systemContext}\n\nUser Question: ${question}` }] }],
      generationConfig: { temperature: 0.3, maxOutputTokens: 1000 }
    });
  }

  function getMockChatAnswer(question) {
    const q = question.toLowerCase();
    const title = currentSession.page?.title || 'this page';
    const domain = currentSession.page?.domain || 'website';
    const summary = currentSession.analysis?.summary || '';

    if (q.includes('about') || q.includes('summary') || q.includes('what is')) return summary || `This page ("${title}" on ${domain}) provides key information.`;
    if (q.includes('learn') || q.includes('tutorial') || q.includes('how to')) return `### How to get started on ${domain}:\n\n**01 — Review Core Concepts**\nRead the primary documentation section.\n\n**02 — Check Prerequisites**\n✓ Web browser\n⚠ Familiarity with core concepts\n\n**03 — Follow Recommended Path**\nUse the step-by-step guide or watch recommended tutorials.`;
    if (q.includes('where') || q.includes('find') || q.includes('navigate')) return `### Navigation Guide for ${domain}:\n\n• **Main Content**: Top section\n• **Navigation Links**: Header area\n• **Settings / Account**: User icon or menu`;
    if (q.includes('missing') || q.includes('risk') || q.includes('prerequisite')) return `### Key Considerations:\n\n1. **Setup Time**: 10-15 minutes.\n2. **Prerequisites**: Required permissions.\n3. **Updates**: Check documentation version.`;
    return `Regarding "${question}" on "${title}": ${domain} provides tools relevant to your request. Proceed with outlined steps or ask for tutorials.`;
  }

  // ============================================================
  // 8. CHAT UI RENDERING
  // ============================================================
  function formatChatMessage(text) {
    if (!text) return '';
    let html = escapeHtml(text);
    html = html.replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>');
    html = html.replace(/__(.*?)__/g, '<strong>$1</strong>');
    html = html.replace(/(^|[^\*])\*([^\*]+)\*([^\*]|$)/g, '$1<em>$2</em>$3');
    html = html.replace(/`([^`]+)`/g, '<code style="background: rgba(0,0,0,0.06); padding: 2px 4px; border-radius: 4px; font-family: monospace; font-size: 12px;">$1</code>');
    html = html.replace(/^#{1,3}\s+(.*$)/gim, '<strong style="display:block; margin-top: 6px; font-size: 13px; color: var(--primary);">$1</strong>');
    html = html.replace(/^[\*\-]\s+(.*$)/gim, '• $1');
    html = html.replace(/\n/g, '<br>');
    return html;
  }

  function appendChatMessage(role, text) {
    const msgDiv = document.createElement('div');
    msgDiv.className = `chat-message ${role}`;
    msgDiv.innerHTML = `<div class="chat-bubble">${formatChatMessage(text)}</div>`;
    chatStream.appendChild(msgDiv);
    scrollChatToBottom();
  }

  function appendVideoCards(videos) {
    if (!videos || videos.length === 0) return;
    const container = document.createElement('div');
    container.className = 'chat-message ai';
    let html = `<span class="text-label-sm" style="color: var(--primary); font-weight: 700; margin-bottom: 4px; display: block;">📹 RECOMMENDED VIDEOS</span><div class="card-stack">`;
    videos.forEach(v => {
      html += `<div class="video-card"><div class="video-thumb-container"><img src="${v.thumbnail}" class="video-thumb" alt="${escapeHtml(v.title)}" onerror="this.src='https://via.placeholder.com/320x180?text=Video'"><div class="video-play-btn"><span class="material-symbols-outlined" style="font-size: 18px;">play_arrow</span></div></div><div class="video-details"><span class="video-title">${escapeHtml(v.title)}</span><span class="video-meta">${escapeHtml(v.channel)} · ${escapeHtml(v.duration)}</span><span class="video-relevance">${escapeHtml(v.relevance)}</span><button class="btn-primary btn-open-video" data-url="${v.url}" style="margin-top: 6px; font-size: 11px; padding: 4px 10px;">Watch video ↗</button></div></div>`;
    });
    html += '</div>';
    container.innerHTML = `<div class="chat-bubble" style="width: 100%;">${html}</div>`;
    chatStream.appendChild(container);
    container.querySelectorAll('.btn-open-video').forEach(btn => btn.addEventListener('click', () => { const u = btn.getAttribute('data-url'); if (u) chrome.tabs.create({ url: u }); }));
    scrollChatToBottom();
  }

  function appendResourceCards(resources) {
    if (!resources || resources.length === 0) return;
    const container = document.createElement('div');
    container.className = 'chat-message ai';
    let html = `<span class="text-label-sm" style="color: var(--primary); font-weight: 700; margin-bottom: 4px; display: block;">🌐 RELEVANT RESOURCES</span><div class="card-stack">`;
    resources.forEach(r => {
      html += `<div class="resource-card"><div style="display: flex; align-items: center; gap: 8px;"><span style="font-size: 18px;">${r.icon}</span><div class="resource-info"><span class="resource-name">${escapeHtml(r.name)}</span><span class="resource-reason">${escapeHtml(r.reason)}</span></div></div><button class="btn-secondary btn-open-res" data-url="${r.url}" style="font-size: 10px; padding: 2px 8px;">Open ↗</button></div>`;
    });
    html += '</div>';
    container.innerHTML = `<div class="chat-bubble" style="width: 100%;">${html}</div>`;
    chatStream.appendChild(container);
    container.querySelectorAll('.btn-open-res').forEach(btn => btn.addEventListener('click', () => { const u = btn.getAttribute('data-url'); if (u) chrome.tabs.create({ url: u }); }));
    scrollChatToBottom();
  }

  function appendChatThinking() {
    const id = 'thinking_' + Date.now();
    const msgDiv = document.createElement('div');
    msgDiv.className = 'chat-message ai';
    msgDiv.id = id;
    msgDiv.innerHTML = `<div class="chat-bubble" style="display: flex; align-items: center; gap: 6px; color: var(--text-muted);"><span class="online-dot pulsing"></span> FindWell is thinking...</div>`;
    chatStream.appendChild(msgDiv);
    scrollChatToBottom();
    return id;
  }

  function removeChatThinking(id) {
    const el = document.getElementById(id);
    if (el) el.remove();
  }

  function scrollChatToBottom() {
    const container = document.getElementById('chat-messages-container');
    if (container) container.scrollTop = container.scrollHeight;
  }

  // ============================================================
  // 9. RESEARCH & EVIDENCE SERVICE
  // ============================================================
  async function triggerDeepResearch(questionText) {
    showView('researching');
    const result = await FindWellProviders.ResearchProvider.research(questionText, currentSession.pageContext);

    currentSession.sources = result.findings.map(f => ({
      title: f.source.name, domain: f.source.domain, claim: f.text,
      confidence: f.confidence + ' CONFIDENCE', url: f.source.url
    }));

    renderEvidenceCards(currentSession.sources);

    const researchSummary = `I've completed deep research on "${questionText}". Findings confirm ${result.overallConfidence}% confidence across ${result.findings.length} verified sources. View citations in Evidence.`;
    appendChatMessage('ai', researchSummary);
    currentSession.messages.push({ role: 'ai', content: researchSummary, timestamp: new Date().toISOString() });
    saveChatMessageToCloud('assistant', researchSummary);
    syncSessionToCloud();
    showView('chat');
  }

  function renderEvidenceCards(sources) {
    const list = document.getElementById('evidence-cards-list');
    if (!list) return;
    list.innerHTML = '';
    sources.forEach(src => {
      const art = document.createElement('article');
      art.className = 'evidence-card';
      art.innerHTML = `<div style="display: flex; justify-content: space-between; align-items: center;"><span class="evidence-chip">${src.confidence}</span><span class="text-body-sm" style="color: var(--text-muted);">${new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</span></div><p class="text-body-md" style="color: var(--text-main); margin: 4px 0;">"${src.claim}"</p><div style="border-top: 1px solid var(--border-muted); padding-top: 6px; display: flex; justify-content: space-between; align-items: center;"><div><span class="text-label-sm" style="color: var(--primary); font-weight: 600; display: block;">${src.title}</span><span class="text-body-sm" style="color: var(--text-muted);">${src.domain}</span></div><button class="icon-btn btn-open-src" data-url="${src.url}"><span class="material-symbols-outlined" style="font-size: 18px;">open_in_new</span></button></div>`;
      list.appendChild(art);
    });
    list.querySelectorAll('.btn-open-src').forEach(btn => btn.addEventListener('click', () => { const u = btn.getAttribute('data-url'); if (u) chrome.tabs.create({ url: u }); }));
  }

  // ============================================================
  // 10. PDF REPORT
  // ============================================================
  function generatePdfReport() { showView('pdfReady'); }

  function executePdfDownload() {
    const page = currentSession.page;
    const analysis = currentSession.analysis || {};
    const messages = currentSession.messages || [];
    const sources = currentSession.sources || [];

    const htmlContent = `<!DOCTYPE html><html><head><meta charset="utf-8"><title>FindWell Research Brief - ${escapeHtml(page.title)}</title><style>body{font-family:'Helvetica Neue',Arial,sans-serif;margin:40px;color:#2F3337;line-height:1.6}.header{border-bottom:2px solid #124343;padding-bottom:16px;margin-bottom:24px}.title{font-size:24px;color:#124343;font-weight:bold;margin:0 0 6px 0}.subtitle{font-size:14px;color:#8DA399;font-weight:600;text-transform:uppercase;letter-spacing:.05em}.meta{font-size:12px;color:#708090;margin-top:4px}.section-title{font-size:15px;color:#124343;border-bottom:1px solid #D1D9D4;padding-bottom:4px;margin-top:24px;text-transform:uppercase;font-weight:bold}.box{background:#E8ECE9;padding:14px;border-radius:8px;margin-top:10px}.card{background:#FDFDFB;border:1px solid #D1D9D4;border-radius:8px;padding:12px;margin-bottom:10px}.qa-user{font-weight:bold;color:#124343;margin-top:12px}.qa-ai{background:#f7f9ff;padding:10px;border-left:3px solid #124343;margin-top:4px;border-radius:4px}.footer{font-size:11px;text-align:center;margin-top:40px;color:#708090;border-top:1px solid #D1D9D4;padding-top:12px}</style></head><body><div class="header"><div class="subtitle">FINDWELL — AI GUIDE TO THE WEB</div><div class="title">RESEARCH BRIEF & GUIDANCE REPORT</div><div class="meta"><strong>Page:</strong> ${escapeHtml(page.title)} (${escapeHtml(page.domain)})</div><div class="meta"><strong>URL:</strong> ${escapeHtml(page.url)}</div><div class="meta"><strong>Generated:</strong> ${new Date().toLocaleString()}</div></div><div class="section-title">1. EXECUTIVE SUMMARY</div><div class="box">${escapeHtml(analysis.summary || 'N/A')}</div>${messages.length > 0 ? `<div class="section-title">2. CONVERSATION HISTORY</div>${messages.map(m => m.role === 'user' ? `<div class="qa-user">Q: ${escapeHtml(m.content)}</div>` : `<div class="qa-ai">${escapeHtml(m.content)}</div>`).join('')}` : ''}${sources.length > 0 ? `<div class="section-title">3. EVIDENCE & CITATIONS</div>${sources.map((s, i) => `<div class="card"><strong>[${i+1}] ${escapeHtml(s.title)}</strong> (${escapeHtml(s.domain)})<br><em>"${escapeHtml(s.claim)}"</em></div>`).join('')}` : ''}<div class="footer">Generated by FindWell — AI Guide to the Web</div><script>window.onload=function(){window.print();}</script></body></html>`;

    const blob = new Blob([htmlContent], { type: 'text/html' });
    const url = URL.createObjectURL(blob);
    chrome.tabs.create({ url: url });
  }

  // ============================================================
  // 11. HISTORY SERVICE (Cloud + Local)
  // ============================================================
  function saveSessionToHistory() {
    chrome.storage.local.get(['researchSessions'], (res) => {
      let sessions = res.researchSessions || [];
      const existingIdx = sessions.findIndex(s => s.id === currentSession.id);
      if (existingIdx >= 0) sessions[existingIdx] = currentSession;
      else sessions.unshift(currentSession);
      if (sessions.length > 20) sessions = sessions.slice(0, 20);
      chrome.storage.local.set({ researchSessions: sessions }, () => renderHistoryList(sessions));
    });
  }

  function getEffectiveUserId() {
    // No placeholder fallback: RLS requires auth.uid() = user_id, and a
    // made-up id can never equal auth.uid() for an unauthenticated
    // request, so writes under a fake id were always silently rejected.
    // Skip cloud sync entirely when not signed in instead of pretending
    // it worked.
    return (currentUser && currentUser.id) ? currentUser.id : null;
  }

  // Shared history: both the extension and the Flutter app read/write
  // public.projects (chat stored in its chat_history jsonb column) so a
  // signed-in user sees the exact same history on both platforms. The
  // old standalone conversations/messages tables are no longer used here.
  async function loadCloudHistory() {
    const userId = getEffectiveUserId();
    if (!userId) return [];
    try {
      const url = `${SUPABASE_URL}/rest/v1/projects?user_id=eq.${userId}&select=*&order=updated_at.desc&limit=10`;
      const res = await fetch(url, {
        headers: {
          'apikey': SUPABASE_ANON_KEY,
          'Authorization': `Bearer ${currentToken}`
        }
      });
      if (res.ok) {
        const data = await res.json();
        return data.map(item => ({
          id: item.id,
          page: { title: item.topic || 'Research Chat', url: 'https://findwell.ai/chat' },
          messages: (item.chat_history || []).map(m => ({
            role: m.role === 'assistant' ? 'ai' : m.role,
            content: m.content
          })),
          createdAt: item.created_at,
          updatedAt: item.updated_at
        }));
      }
      console.warn('Failed to load cloud history:', res.status, await res.text());
    } catch (err) {
      console.warn('Failed to load cloud history:', err);
    }
    return [];
  }

  async function syncSessionToCloud() {
    const userId = getEffectiveUserId();
    if (!currentSession || !userId) return;
    try {
      const projTitle = currentSession.page?.title || 'Extension Research Chat';
      // Keep {role, content} shape identical to the Flutter app's
      // chatHistory entries so either platform can read what the other
      // wrote.
      const chatHistory = (currentSession.messages || []).map(m => ({
        role: m.role === 'ai' ? 'assistant' : m.role,
        content: m.content
      }));
      const res = await fetch(`${SUPABASE_URL}/rest/v1/projects`, {
        method: 'POST',
        headers: {
          'apikey': SUPABASE_ANON_KEY,
          'Authorization': `Bearer ${currentToken}`,
          'Content-Type': 'application/json',
          'Prefer': 'resolution=merge-duplicates,return=representation'
        },
        body: JSON.stringify({
          id: currentSession.id,
          user_id: userId,
          topic: projTitle,
          domain: currentSession.page?.domain || null,
          chat_history: chatHistory,
          updated_at: new Date().toISOString()
        })
      });
      if (!res.ok) {
        console.warn('Failed to sync session to cloud:', res.status, await res.text());
      }
    } catch (e) {
      console.warn('Failed to sync session to cloud:', e);
    }
  }

  function renderHistoryList(sessions) {
    const list = document.getElementById('history-sessions-list');
    if (!list) return;
    list.innerHTML = '';

    if (!sessions || sessions.length === 0) {
      list.innerHTML = `<p class="text-body-sm" style="color: var(--text-muted); text-align: center;">No previous research sessions.</p>`;
      return;
    }

    sessions.forEach(s => {
      const item = document.createElement('div');
      item.className = 'card-context';
      item.style.cursor = 'pointer';
      item.innerHTML = `<div style="display: flex; justify-content: space-between; align-items: flex-start;"><h3 class="text-h3" style="margin: 0; max-width: 260px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">${escapeHtml(s.page?.title || 'Session')}</h3><span class="text-label-sm" style="color: var(--text-muted);">${new Date(s.createdAt).toLocaleDateString()}</span></div><span class="text-body-sm" style="color: var(--text-muted);">${escapeHtml(s.page?.domain || '')}</span><div style="display: flex; justify-content: space-between; align-items: center; margin-top: 4px;"><span class="online-badge" style="font-size: 10px;">● ${(s.messages || []).length} messages</span><span class="material-symbols-outlined" style="font-size: 16px; color: var(--primary);">arrow_forward</span></div>`;
      item.addEventListener('click', () => {
        currentSession = s;
        if (s.analysis) renderAnalysisDashboard(s.analysis, s.pageContext);
        showView('analysis');
      });
      list.appendChild(item);
    });
  }

  // ============================================================
  // 12. GOAL CARDS
  // ============================================================
  document.querySelectorAll('.goal-card').forEach(card => {
    card.addEventListener('click', () => {
      const goal = card.getAttribute('data-goal');
      currentSession.activeGoal = goal;
      const goalPrompts = {
        understand: 'Can you explain this page and its main concepts simply?',
        learn: 'How can I learn the topics on this page step-by-step?',
        find: 'Where do I find the major sections, settings, and options on this website?',
        do: 'What should I do step-by-step to accomplish tasks on this website?',
        research: 'Can you research external evidence, sources, and alternatives for this topic?',
        decide: 'Can you compare options and alternatives for this page with pros and cons?'
      };
      showView('chat');
      submitChatMessage(goalPrompts[goal] || 'Can you guide me on this page?');
    });
  });

  // ============================================================
  // 13. EVENT HANDLERS & BUTTON ACTIONS
  // ============================================================
  if (navBtnAnalysis) navBtnAnalysis.addEventListener('click', () => showView('analysis'));
  if (navBtnChat) navBtnChat.addEventListener('click', () => showView('chat'));
  if (navBtnHistory) navBtnHistory.addEventListener('click', () => {
    // Load from cloud first, then local fallback
    loadCloudHistory().then(cloudSessions => {
      if (cloudSessions.length > 0) {
        renderHistoryList(cloudSessions);
      } else {
        chrome.storage.local.get(['researchSessions'], (res) => renderHistoryList(res.researchSessions || []));
      }
      showView('history');
    });
  });

  if (headerAccountBtn) headerAccountBtn.addEventListener('click', () => {
    if (currentUser) {
      showView('settings');
    } else {
      showView('auth');
    }
  });

  const btnGuideAround = document.getElementById('btn-guide-around');
  if (btnGuideAround) btnGuideAround.addEventListener('click', () => {
    showView('chat');
    submitChatMessage('Guide me around this website and explain where everything is.');
  });

  const btnStartChat = document.getElementById('btn-start-chat');
  if (btnStartChat) btnStartChat.addEventListener('click', () => showView('chat'));

  const btnResearchDeeper = document.getElementById('btn-research-deeper');
  if (btnResearchDeeper) btnResearchDeeper.addEventListener('click', () => triggerDeepResearch('Research deeper options'));

  const btnBackEvidence = document.getElementById('btn-back-to-chat-from-evidence');
  if (btnBackEvidence) btnBackEvidence.addEventListener('click', () => showView('chat'));

  const btnContinuePdf = document.getElementById('btn-continue-chat-from-pdf');
  if (btnContinuePdf) btnContinuePdf.addEventListener('click', () => showView('chat'));

  const btnDownloadPdf = document.getElementById('btn-download-pdf');
  if (btnDownloadPdf) btnDownloadPdf.addEventListener('click', () => executePdfDownload());

  if (headerContextBtn) headerContextBtn.addEventListener('click', () => {
    const ctx = currentSession.pageContext || {};
    const ctxTitle = document.getElementById('ctx-page-title');
    const ctxDomain = document.getElementById('ctx-page-domain');
    const ctxTime = document.getElementById('ctx-page-time');
    const ctxStats = document.getElementById('ctx-page-stats');
    if (ctxTitle) ctxTitle.textContent = currentSession.page.title || '-';
    if (ctxDomain) ctxDomain.textContent = currentSession.page.domain || '-';
    if (ctxTime) ctxTime.textContent = ctx.capturedAt ? new Date(ctx.capturedAt).toLocaleTimeString() : '-';
    if (ctxStats) ctxStats.textContent = ctx.content ? `Analyzed ${ctx.content.length} characters` : 'Page content analyzed';
    showView('context');
  });

  const btnCloseCtx = document.getElementById('btn-close-context');
  if (btnCloseCtx) btnCloseCtx.addEventListener('click', () => showView('analysis'));

  const btnCtxRefresh = document.getElementById('btn-ctx-refresh');
  if (btnCtxRefresh) btnCtxRefresh.addEventListener('click', () => initPageAnalysis());

  const btnRefreshPage = document.getElementById('btn-refresh-page-context');
  if (btnRefreshPage) btnRefreshPage.addEventListener('click', () => initPageAnalysis());

  const btnCtxClear = document.getElementById('btn-ctx-clear');
  if (btnCtxClear) btnCtxClear.addEventListener('click', () => {
    currentSession.pageContext = null;
    currentSession.analysis = null;
    alert('Page context cleared.');
    showView('analysis');
  });

  const btnCloseSettings = document.getElementById('btn-close-settings');
  if (btnCloseSettings) btnCloseSettings.addEventListener('click', () => showView('analysis'));

  const btnSettingsLogout = document.getElementById('btn-settings-logout');
  if (btnSettingsLogout) btnSettingsLogout.addEventListener('click', () => handleLogout());

  const headerSettingsBtn = document.getElementById('header-settings-btn');
  if (headerSettingsBtn) headerSettingsBtn.addEventListener('click', () => { updateModelSelectionUI(); initModelSelectionHandlers(); showView('settings'); });

  const btnDismissWarning = document.getElementById('btn-dismiss-warning');
  if (btnDismissWarning) btnDismissWarning.addEventListener('click', () => showView('analysis'));

  const btnErrorRetry = document.getElementById('btn-error-retry');
  if (btnErrorRetry) btnErrorRetry.addEventListener('click', () => initPageAnalysis());

  // ============================================================
  // 14. UTILITIES
  // ============================================================
  function delay(ms) { return new Promise(r => setTimeout(r, ms)); }

  function escapeHtml(str) {
    if (!str) return '';
    return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#039;');
  }

  // ============================================================
  // 15. BOOT: LOGIN-FIRST GATE
  // ============================================================
  initAuthView();

  chrome.storage.local.get(['findwell_session'], (res) => {
    if (res.findwell_session && res.findwell_session.user && res.findwell_session.access_token) {
      currentUser = res.findwell_session.user;
      currentToken = res.findwell_session.access_token;

      // Update settings display
      const settingsEmail = document.getElementById('settings-user-email');
      if (settingsEmail) settingsEmail.innerText = currentUser.email || 'User';

      // Start main app
      onAuthSuccess();
    } else {
      // No session — stay on auth view (already default)
      showView('auth');
    }
  });

  // Test Connection Direct Binding (Matches Mobile APK)
  const btnTestConn = document.getElementById('btn-test-connection');
  const statusTestConn = document.getElementById('test-connection-status');
  if (btnTestConn) {
    btnTestConn.addEventListener('click', async () => {
      btnTestConn.disabled = true;
      btnTestConn.innerHTML = `<span class="material-symbols-outlined pulsing" style="font-size: 16px;">sync</span> Testing connection...`;
      if (statusTestConn) {
        statusTestConn.style.display = 'block';
        statusTestConn.style.background = 'rgba(124, 58, 237, 0.08)';
        statusTestConn.style.border = '1px solid rgba(124, 58, 237, 0.2)';
        statusTestConn.style.color = '#7C3AED';
        statusTestConn.innerHTML = 'Connecting to <b>' + (currentSelectedModel || '4-LLM Ensemble') + '</b>...';
      }

      try {
        const testPrompt = {
          contents: [{ parts: [{ text: 'Say "connected" in one word.' }] }]
        };
        const resText = await fetchMultiLLM(testPrompt);
        if (statusTestConn) {
          const modelDisplayName = getSelectedModelDisplayName();
          statusTestConn.style.display = 'block';
          statusTestConn.style.background = 'rgba(16, 185, 129, 0.1)';
          statusTestConn.style.border = '1px solid rgba(16, 185, 129, 0.3)';
          statusTestConn.style.color = '#047857';
          statusTestConn.innerHTML = `✓ Connected to <b>${modelDisplayName}</b>!<br><span style="font-size:10px; color:#475569;">API Response: "${resText.substring(0, 40)}"</span>`;
        }
      } catch (err) {
        if (statusTestConn) {
          statusTestConn.style.display = 'block';
          statusTestConn.style.background = 'rgba(239, 68, 68, 0.1)';
          statusTestConn.style.border = '1px solid rgba(239, 68, 68, 0.3)';
          statusTestConn.style.color = '#EF4444';
          statusTestConn.innerHTML = `✗ Connection failed: ${err.message || 'API error'}`;
        }
      } finally {
        btnTestConn.disabled = false;
        btnTestConn.innerHTML = `<span class="material-symbols-outlined" style="font-size: 16px;">wifi_tethering</span> Test Connection`;
      }
    });
  }
});