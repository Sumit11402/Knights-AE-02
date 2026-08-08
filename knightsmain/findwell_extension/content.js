/* content.js - FindWell Page Context Collector & Guide Overlay */

chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.action === 'getPageMetadata') {
    try {
      // 1. Favicon URL
      let faviconUrl = '';
      const linkNodes = document.querySelectorAll('link[rel*="icon"]');
      if (linkNodes && linkNodes.length > 0) {
        faviconUrl = linkNodes[0].href;
      }
      if (!faviconUrl) {
        faviconUrl = `${window.location.protocol}//${window.location.hostname}/favicon.ico`;
      }

      // 2. Selection text if user highlighted anything
      const selectedText = window.getSelection() ? window.getSelection().toString().trim() : '';

      // 3. Extract Headings (h1, h2, h3)
      const headings = [];
      document.querySelectorAll('h1, h2, h3').forEach((h) => {
        const text = h.innerText.trim();
        if (text && text.length > 3 && headings.length < 15) {
          headings.push({ tag: h.tagName.toLowerCase(), text });
        }
      });

      // 4. Meta Description
      let metaDescription = '';
      const metaDescEl = document.querySelector('meta[name="description"]') || document.querySelector('meta[property="og:description"]');
      if (metaDescEl) {
        metaDescription = metaDescEl.getAttribute('content') || '';
      }

      // 5. Main Content Text Extraction
      let pageContent = '';
      const articleOrMain = document.querySelector('article') || document.querySelector('main') || document.body;
      if (articleOrMain) {
        pageContent = articleOrMain.innerText || '';
      }
      pageContent = pageContent.replace(/\s+/g, ' ').trim();
      if (pageContent.length > 8000) {
        pageContent = pageContent.substring(0, 8000) + '...';
      }

      // 6. Table summaries
      const tablesSummary = [];
      document.querySelectorAll('table').forEach((table, idx) => {
        if (idx < 3) {
          const text = table.innerText.replace(/\s+/g, ' ').trim();
          if (text.length > 20 && text.length < 500) {
            tablesSummary.push(text);
          }
        }
      });

      // 7. Navigation elements extraction
      const navigationItems = [];
      const navEls = document.querySelectorAll('nav a, header a, [role="navigation"] a');
      const seenNavText = new Set();
      navEls.forEach((a) => {
        const text = (a.innerText || a.textContent || '').trim();
        if (text && text.length > 1 && text.length < 60 && !seenNavText.has(text.toLowerCase()) && navigationItems.length < 20) {
          seenNavText.add(text.toLowerCase());
          navigationItems.push({
            text: text,
            href: a.href || '',
            ariaLabel: a.getAttribute('aria-label') || ''
          });
        }
      });

      // 8. Buttons and interactive elements
      const interactiveElements = [];
      document.querySelectorAll('button, [role="button"], input[type="submit"], a.btn, a.button').forEach((el) => {
        const text = (el.innerText || el.textContent || el.value || el.getAttribute('aria-label') || '').trim();
        if (text && text.length > 1 && text.length < 80 && interactiveElements.length < 15) {
          interactiveElements.push({
            tag: el.tagName.toLowerCase(),
            text: text,
            type: el.type || el.getAttribute('role') || 'button'
          });
        }
      });

      // 9. Forms detection
      const forms = [];
      document.querySelectorAll('form').forEach((form, idx) => {
        if (idx < 5) {
          const inputs = form.querySelectorAll('input, textarea, select');
          const labels = [];
          inputs.forEach((inp) => {
            const label = inp.getAttribute('placeholder') || inp.getAttribute('aria-label') || inp.getAttribute('name') || '';
            if (label) labels.push(label);
          });
          forms.push({
            action: form.action || '',
            method: form.method || 'get',
            fields: labels.slice(0, 8)
          });
        }
      });

      // 10. Page sections by landmark/heading structure
      const pageSections = [];
      document.querySelectorAll('section[aria-label], section[id], [role="region"], main > div[id]').forEach((sec) => {
        const label = sec.getAttribute('aria-label') || sec.id || '';
        const heading = sec.querySelector('h1, h2, h3');
        const headingText = heading ? heading.innerText.trim() : '';
        if ((label || headingText) && pageSections.length < 10) {
          pageSections.push({ id: sec.id || '', label: label, heading: headingText });
        }
      });

      sendResponse({
        title: document.title || window.location.hostname,
        domain: window.location.hostname,
        url: window.location.href,
        favicon: faviconUrl,
        selectedText: selectedText,
        headings: headings,
        metaDescription: metaDescription,
        content: pageContent,
        tablesSummary: tablesSummary,
        navigationItems: navigationItems,
        interactiveElements: interactiveElements,
        forms: forms,
        pageSections: pageSections,
        capturedAt: new Date().toISOString()
      });
    } catch (err) {
      console.error('FindWell content script error:', err);
      sendResponse({
        title: document.title || 'Unknown Page',
        domain: window.location.hostname || '',
        url: window.location.href || '',
        favicon: '',
        content: 'Error reading page content.',
        navigationItems: [],
        interactiveElements: [],
        forms: [],
        pageSections: [],
        capturedAt: new Date().toISOString()
      });
    }
  }

  // Highlight an element on the page
  if (request.action === 'highlightElement') {
    try {
      // Remove any existing highlights
      document.querySelectorAll('.findwell-highlight-overlay').forEach(el => el.remove());

      const query = request.selector || request.text;
      let target = null;

      // Try CSS selector first
      if (request.selector) {
        try { target = document.querySelector(request.selector); } catch (e) { /* ignore */ }
      }

      // Fallback: find by text content
      if (!target && request.text) {
        const allEls = document.querySelectorAll('a, button, [role="button"], nav *, h1, h2, h3, h4, label, li');
        for (const el of allEls) {
          if ((el.innerText || '').trim().toLowerCase().includes(request.text.toLowerCase())) {
            target = el;
            break;
          }
        }
      }

      if (target) {
        target.scrollIntoView({ behavior: 'smooth', block: 'center' });
        const overlay = document.createElement('div');
        overlay.className = 'findwell-highlight-overlay';
        const rect = target.getBoundingClientRect();
        Object.assign(overlay.style, {
          position: 'fixed',
          top: (rect.top - 4) + 'px',
          left: (rect.left - 4) + 'px',
          width: (rect.width + 8) + 'px',
          height: (rect.height + 8) + 'px',
          border: '3px solid #124343',
          borderRadius: '8px',
          backgroundColor: 'rgba(18, 67, 67, 0.08)',
          zIndex: '2147483647',
          pointerEvents: 'none',
          boxShadow: '0 0 0 4px rgba(18, 67, 67, 0.15), 0 0 20px rgba(18, 67, 67, 0.1)',
          transition: 'opacity 0.3s ease',
          animation: 'findwell-pulse 2s ease-in-out infinite'
        });
        document.body.appendChild(overlay);

        // Add animation keyframes if not present
        if (!document.getElementById('findwell-highlight-styles')) {
          const style = document.createElement('style');
          style.id = 'findwell-highlight-styles';
          style.textContent = `
            @keyframes findwell-pulse {
              0%, 100% { box-shadow: 0 0 0 4px rgba(18,67,67,0.15), 0 0 20px rgba(18,67,67,0.1); }
              50% { box-shadow: 0 0 0 6px rgba(18,67,67,0.25), 0 0 30px rgba(18,67,67,0.15); }
            }
          `;
          document.head.appendChild(style);
        }

        // Auto-remove after 5 seconds
        setTimeout(() => { overlay.remove(); }, 5000);
        sendResponse({ found: true, text: target.innerText?.trim().substring(0, 100) });
      } else {
        sendResponse({ found: false });
      }
    } catch (err) {
      sendResponse({ found: false, error: err.message });
    }
  }

  return true; // Keep message port open for async response
});
