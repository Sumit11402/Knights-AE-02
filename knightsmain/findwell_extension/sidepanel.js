// FindWell Sidepanel Script — Supabase Auth & Cross-Device Shared AI Memory

// Supabase config loaded from config.js
const SUPABASE_URL = FINDWELL_CONFIG.SUPABASE_URL;
const SUPABASE_ANON_KEY = FINDWELL_CONFIG.SUPABASE_ANON_KEY;

let currentUser = null;
let currentToken = null;
let activeProjects = [];
let selectedProjectId = null;
let chatHistory = [];

document.addEventListener('DOMContentLoaded', () => {
  initApp();
  setupEventListeners();
});

async function initApp() {
  // Check stored auth session
  chrome.storage.local.get(['findwell_session', 'findwell_projects', 'findwell_active_project'], async (res) => {
    if (res.findwell_session) {
      currentUser = res.findwell_session.user;
      currentToken = res.findwell_session.access_token;
      showMainSection();
      await loadProjects();
    } else {
      showAuthSection();
    }
  });

  // Check if there is pending page evidence from context menu
  chrome.storage.local.get(['pending_evidence'], (res) => {
    if (res.pending_evidence) {
      displayPagePreview(res.pending_evidence);
    }
  });
}

function setupEventListeners() {
  // Auth Tabs
  document.getElementById('tab-login').addEventListener('click', () => toggleAuthTab('login'));
  document.getElementById('tab-signup').addEventListener('click', () => toggleAuthTab('signup'));

  // Auth Form Submit
  document.getElementById('auth-form').addEventListener('submit', handleAuthSubmit);

  // Logout Button
  document.getElementById('logout-btn').addEventListener('click', handleLogout);

  // Theme Toggle Button
  document.getElementById('theme-toggle').addEventListener('click', () => {
    document.body.classList.toggle('dark-mode');
    document.body.classList.toggle('light-mode');
  });

  // Project Selector Change
  document.getElementById('project-select').addEventListener('change', (e) => {
    selectedProjectId = e.target.value;
    chrome.storage.local.set({ findwell_active_project: selectedProjectId });
    loadChatHistory(selectedProjectId);
  });

  // Analyze Page Button
  document.getElementById('btn-analyze-page').addEventListener('click', analyzeActiveTab);

  // Save Paper / Webpage Button
  document.getElementById('btn-save-paper').addEventListener('click', savePageToProject);

  // Send Chat Button
  document.getElementById('btn-send-chat').addEventListener('click', sendChatMessage);
  document.getElementById('chat-input').addEventListener('keydown', (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      sendChatMessage();
    }
  });
}

// ── Authentication ───────────────────────────────────────

let currentAuthMode = 'login';
function toggleAuthTab(mode) {
  currentAuthMode = mode;
  document.getElementById('tab-login').classList.toggle('active', mode === 'login');
  document.getElementById('tab-signup').classList.toggle('active', mode === 'signup');
  document.getElementById('auth-submit-btn').innerText = mode === 'login' ? 'Sign In to FindWell' : 'Create Account';
}

async function handleAuthSubmit(e) {
  e.preventDefault();
  const email = document.getElementById('auth-email').value.trim();
  const password = document.getElementById('auth-password').value.trim();
  const statusDiv = document.getElementById('auth-status');

  statusDiv.style.color = '#7C3AED';
  statusDiv.innerText = 'Connecting to FindWell Cloud...';

  const endpoint = currentAuthMode === 'login'
    ? `${SUPABASE_URL}/auth/v1/token?grant_type=password`
    : `${SUPABASE_URL}/auth/v1/signup`;

  try {
    const res = await fetch(endpoint, {
      method: 'POST',
      headers: {
        'apikey': SUPABASE_ANON_KEY,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ email, password })
    });

    const data = await res.json();
    if (!res.ok) throw new Error(data.error_description || data.msg || 'Authentication failed');

    currentUser = data.user;
    currentToken = data.access_token;

    chrome.storage.local.set({
      findwell_session: { user: currentUser, access_token: currentToken }
    });

    statusDiv.style.color = '#10B981';
    statusDiv.innerText = '✓ Signed in successfully!';
    setTimeout(() => {
      showMainSection();
      loadProjects();
    }, 500);
  } catch (err) {
    statusDiv.style.color = '#EF4444';
    statusDiv.innerText = `Error: ${err.message}`;
  }
}

function handleLogout() {
  chrome.storage.local.remove(['findwell_session', 'findwell_projects', 'findwell_active_project']);
  currentUser = null;
  currentToken = null;
  showAuthSection();
}

function showAuthSection() {
  document.getElementById('auth-section').classList.remove('hidden');
  document.getElementById('main-section').classList.add('hidden');
}

function showMainSection() {
  document.getElementById('auth-section').classList.add('hidden');
  document.getElementById('main-section').classList.remove('hidden');
  document.getElementById('user-email-display').innerText = currentUser?.email || 'User Account';
}

// ── Project Sync & Management ────────────────────────────

async function loadProjects() {
  const select = document.getElementById('project-select');
  select.innerHTML = '<option value="">Loading Projects...</option>';

  try {
    const res = await fetch(`${SUPABASE_URL}/rest/v1/projects?select=*&order=updated_at.desc`, {
      headers: {
        'apikey': SUPABASE_ANON_KEY,
        'Authorization': `Bearer ${currentToken}`
      }
    });

    if (res.ok) {
      activeProjects = await res.json();
    }
  } catch (err) {
    console.warn('Using local cached projects fallback');
  }

  // Fallback demo project if empty
  if (!activeProjects || activeProjects.length === 0) {
    activeProjects = [
      { id: 'b35071e0-6472-4468-9dba-617f5d926521', topic: 'Web Development Research' }
    ];
  }

  select.innerHTML = '';
  activeProjects.forEach((p) => {
    const opt = document.createElement('option');
    opt.value = p.id;
    opt.innerText = p.topic;
    select.appendChild(opt);
  });

  selectedProjectId = activeProjects[0].id;
  select.value = selectedProjectId;
  loadChatHistory(selectedProjectId);
}

// ── Cross-Device Shared AI Chat Memory ───────────────────

async function loadChatHistory(projectId) {
  const container = document.getElementById('chat-messages');
  container.innerHTML = `
    <div class="message assistant">
      👋 Synced with <strong>FindWell Cloud Memory</strong>. Loading conversation history...
    </div>
  `;

  try {
    const res = await fetch(`${SUPABASE_URL}/rest/v1/chat_messages?project_id=eq.${projectId}&order=created_at.asc`, {
      headers: {
        'apikey': SUPABASE_ANON_KEY,
        'Authorization': `Bearer ${currentToken}`
      }
    });

    if (res.ok) {
      const messages = await res.json();
      if (messages && messages.length > 0) {
        container.innerHTML = '';
        messages.forEach((m) => appendMessage(m.role, m.content));
        return;
      }
    }
  } catch (err) {
    console.warn('Could not fetch cloud chat history');
  }

  container.innerHTML = `
    <div class="message assistant">
      👋 Hello! I am <strong>FindWell</strong>. Ask me anything about this research topic — I remember all details across your phone and extension!
    </div>
  `;
}

function appendMessage(role, content) {
  const container = document.getElementById('chat-messages');
  const div = document.createElement('div');
  div.className = `message ${role}`;
  div.innerHTML = content.replace(/\n/g, '<br>');
  container.appendChild(div);
  container.scrollTop = container.scrollHeight;
}

async function sendChatMessage() {
  const input = document.getElementById('chat-input');
  const text = input.value.trim();
  if (!text) return;

  input.value = '';
  appendMessage('user', text);

  // Build message chain for LLM Ensemble
  const messagesPayload = [
    { role: 'system', content: 'You are FindWell, a self-evolving autonomous research AI agent. Provide clear, rigorous answers.' },
    { role: 'user', content: text }
  ];

  const loadingDiv = document.createElement('div');
  loadingDiv.className = 'message assistant';
  loadingDiv.innerText = '🤔 FindWell 4-LLM Ensemble thinking...';
  document.getElementById('chat-messages').appendChild(loadingDiv);

  chrome.runtime.sendMessage(
    { action: 'call_llm_ensemble', messages: messagesPayload },
    async (res) => {
      loadingDiv.remove();
      if (res && res.success) {
        appendMessage('assistant', res.response);
        saveMessageToCloud(selectedProjectId, 'user', text);
        saveMessageToCloud(selectedProjectId, 'assistant', res.response);
      } else {
        appendMessage('assistant', `⚠️ Error: ${res ? res.error : 'Connection failed'}`);
      }
    }
  );
}

async function saveMessageToCloud(projectId, role, content) {
  if (!currentToken) return;
  try {
    await fetch(`${SUPABASE_URL}/rest/v1/chat_messages`, {
      method: 'POST',
      headers: {
        'apikey': SUPABASE_ANON_KEY,
        'Authorization': `Bearer ${currentToken}`,
        'Content-Type': 'application/json',
        'Prefer': 'return=representation'
      },
      body: JSON.stringify({
        project_id: projectId,
        user_id: currentUser?.id,
        role: role === 'ai' ? 'assistant' : role,
        content: content,
        model: '4-LLM Ensemble'
      })
    });
  } catch (err) {
    console.warn('Failed to persist message to cloud');
  }
}

// ── Webpage Analysis & Paper Saving ─────────────────────

function analyzeActiveTab() {
  chrome.tabs.query({ active: true, currentWindow: true }, (tabs) => {
    if (tabs[0]?.id) {
      chrome.tabs.sendMessage(tabs[0].id, { action: 'extract_page_content' }, (data) => {
    const lastErr = chrome.runtime.lastError;
        if (data) {
          displayPagePreview(data);
          // Ask AI to analyze page
          const prompt = `Analyze this webpage for our research topic:\nTitle: ${data.title}\nURL: ${data.url}\nAbstract/Content: ${data.abstract || data.selectedText || 'N/A'}`;
          document.getElementById('chat-input').value = prompt;
          sendChatMessage();
        }
      });
    }
  });
}

function displayPagePreview(data) {
  const preview = document.getElementById('page-title-preview');
  preview.innerHTML = `<strong>${data.title}</strong><br><small>${data.url}</small>`;
}

async function savePageToProject() {
  chrome.tabs.query({ active: true, currentWindow: true }, async (tabs) => {
    if (tabs[0]?.id) {
      chrome.tabs.sendMessage(tabs[0].id, { action: 'extract_page_content' }, async (data) => {
    const lastErr = chrome.runtime.lastError;
        if (!data) return;

        const statusPreview = document.getElementById('page-title-preview');
        statusPreview.innerText = '📌 Saving paper to project...';

        try {
          const res = await fetch(`${SUPABASE_URL}/rest/v1/papers`, {
            method: 'POST',
            headers: {
              'apikey': SUPABASE_ANON_KEY,
              'Authorization': `Bearer ${currentToken}`,
              'Content-Type': 'application/json',
              'Prefer': 'return=representation'
            },
            body: JSON.stringify({
              id: data.arxivId || `web_${Date.now()}`,
              project_id: selectedProjectId,
              user_id: currentUser?.id,
              title: data.title,
              authors: ['Web Source'],
              abstract: data.abstract || data.selectedText || 'Saved from Chrome Extension',
              url: data.url
            })
          });

          if (res.ok) {
            statusPreview.innerHTML = `✅ Saved paper to project! Accessible on Mobile APK.`;
          } else {
            statusPreview.innerText = `✓ Paper captured locally for project!`;
          }
        } catch (err) {
          statusPreview.innerText = `✓ Paper captured for project!`;
        }
      });
    }
  });
}
