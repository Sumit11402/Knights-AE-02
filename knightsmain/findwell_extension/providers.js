/* providers.js - FindWell Provider Abstraction Layer
 *
 * Architecture: Each provider has a real implementation (API-backed)
 * and a mock implementation (offline fallback). The factory selects
 * based on configuration. All providers can be swapped for secure
 * backend implementations later.
 */

const FindWellProviders = (() => {

  // ============================================================
  // VIDEO PROVIDER
  // ============================================================
  // Mock videos using real YouTube IDs for common topics
  const VIDEO_LIBRARY = {
    react: [
      { id: 'Tn6-PIqc4UM', title: 'React in 100 Seconds', channel: 'Fireship', duration: '2 min', topic: 'react' },
      { id: 'w7ejDZ8SWv8', title: 'React JS Crash Course', channel: 'Traversy Media', duration: '1h 48min', topic: 'react' },
      { id: 'bMknfKXIFA8', title: 'React Course - Beginner Tutorial', channel: 'freeCodeCamp', duration: '12h', topic: 'react' },
    ],
    javascript: [
      { id: 'PkZNo7MFNFg', title: 'JavaScript Full Course for Beginners', channel: 'freeCodeCamp', duration: '3h 26min', topic: 'javascript' },
      { id: 'W6NZfCJ1qdQ', title: 'JavaScript in 100 Seconds', channel: 'Fireship', duration: '2 min', topic: 'javascript' },
      { id: 'lkIFF4maKMU', title: 'JavaScript Crash Course For Beginners', channel: 'Traversy Media', duration: '1h 40min', topic: 'javascript' },
    ],
    python: [
      { id: 'rfscVS0vtbw', title: 'Learn Python - Full Course', channel: 'freeCodeCamp', duration: '4h 27min', topic: 'python' },
      { id: 'x7X9w_GIm1s', title: 'Python in 100 Seconds', channel: 'Fireship', duration: '2 min', topic: 'python' },
      { id: '_uQrJ0TkZlc', title: 'Python Tutorial for Beginners', channel: 'Programming with Mosh', duration: '6h 14min', topic: 'python' },
    ],
    css: [
      { id: 'OXGznpKZ_sA', title: 'CSS Full Course', channel: 'freeCodeCamp', duration: '6h 18min', topic: 'css' },
      { id: '1PnVor36_40', title: 'CSS in 100 Seconds', channel: 'Fireship', duration: '2 min', topic: 'css' },
    ],
    html: [
      { id: 'qz0aGYrrlhU', title: 'HTML Tutorial for Beginners', channel: 'Programming with Mosh', duration: '1h 9min', topic: 'html' },
      { id: 'UB1O30fR-EE', title: 'HTML Crash Course For Absolute Beginners', channel: 'Traversy Media', duration: '1h', topic: 'html' },
    ],
    git: [
      { id: 'RGOj5yH7evk', title: 'Git and GitHub for Beginners', channel: 'freeCodeCamp', duration: '1h 8min', topic: 'git' },
      { id: 'USjZOLrgSRA', title: 'Git & GitHub Crash Course', channel: 'Brad Traversy', duration: '32 min', topic: 'git' },
    ],
    api: [
      { id: 's7wmiS2mSXY', title: 'APIs for Beginners', channel: 'freeCodeCamp', duration: '3h 33min', topic: 'api' },
      { id: 'GZvSYJDk-us', title: 'REST API Concepts', channel: 'WebConcepts', duration: '8 min', topic: 'api' },
    ],
    design: [
      { id: 'c9Wg6Cb_YP8', title: 'UI Design Tutorial For Beginners', channel: 'DesignCourse', duration: '23 min', topic: 'design' },
      { id: 'wIuVvCuiJhU', title: 'UX Design Course for Beginners', channel: 'freeCodeCamp', duration: '2h', topic: 'design' },
    ],
    general: [
      { id: 'bJzb-RuUcMU', title: 'How The Internet Works', channel: 'Lesics', duration: '10 min', topic: 'general' },
      { id: 'ok-plXXHlWw', title: 'How Computers Work', channel: 'Code.org', duration: '5 min', topic: 'general' },
    ]
  };

  function detectTopics(text) {
    const lower = (text || '').toLowerCase();
    const topics = [];
    const keywords = {
      react: ['react', 'jsx', 'component', 'hooks', 'usestate', 'useeffect'],
      javascript: ['javascript', 'js ', 'node', 'typescript', 'es6', 'dom', 'function'],
      python: ['python', 'pip', 'django', 'flask', 'pandas', 'numpy'],
      css: ['css', 'stylesheet', 'flexbox', 'grid', 'animation', 'responsive'],
      html: ['html', 'markup', 'semantic', 'tags', 'element'],
      git: ['git', 'github', 'commit', 'branch', 'merge', 'repository'],
      api: ['api', 'rest', 'endpoint', 'fetch', 'request', 'response', 'graphql'],
      design: ['design', 'ui', 'ux', 'figma', 'prototype', 'wireframe', 'layout']
    };
    for (const [topic, kws] of Object.entries(keywords)) {
      if (kws.some(kw => lower.includes(kw))) topics.push(topic);
    }
    if (topics.length === 0) topics.push('general');
    return topics;
  }

  const VideoProvider = {
    getVideos(question, pageContext) {
      const combined = `${question} ${pageContext?.title || ''} ${pageContext?.domain || ''}`;
      const topics = detectTopics(combined);
      const results = [];
      for (const topic of topics) {
        const lib = VIDEO_LIBRARY[topic] || VIDEO_LIBRARY.general;
        lib.forEach(v => {
          if (!results.find(r => r.id === v.id)) {
            results.push({
              ...v,
              thumbnail: `https://img.youtube.com/vi/${v.id}/mqdefault.jpg`,
              url: `https://www.youtube.com/watch?v=${v.id}`,
              relevance: `Recommended for learning ${topic} concepts discussed on this page.`
            });
          }
        });
      }
      return results.slice(0, 4);
    }
  };

  // ============================================================
  // RESOURCE PROVIDER
  // ============================================================
  const RESOURCE_LIBRARY = {
    coding: [
      { name: 'MDN Web Docs', domain: 'developer.mozilla.org', url: 'https://developer.mozilla.org', icon: '📄', reason: 'Official web technology reference and documentation' },
      { name: 'Stack Overflow', domain: 'stackoverflow.com', url: 'https://stackoverflow.com', icon: '💬', reason: 'Community answers for coding questions' },
      { name: 'W3Schools', domain: 'w3schools.com', url: 'https://w3schools.com', icon: '🎓', reason: 'Interactive tutorials and references' },
      { name: 'GitHub', domain: 'github.com', url: 'https://github.com', icon: '🐙', reason: 'Open source code examples and repositories' },
      { name: 'GeeksforGeeks', domain: 'geeksforgeeks.org', url: 'https://geeksforgeeks.org', icon: '📚', reason: 'Programming tutorials and practice' },
    ],
    academic: [
      { name: 'Google Scholar', domain: 'scholar.google.com', url: 'https://scholar.google.com', icon: '🎓', reason: 'Academic papers and citations' },
      { name: 'ResearchGate', domain: 'researchgate.net', url: 'https://researchgate.net', icon: '🔬', reason: 'Research collaboration and papers' },
      { name: 'arXiv', domain: 'arxiv.org', url: 'https://arxiv.org', icon: '📑', reason: 'Preprint scientific papers' },
      { name: 'PubMed', domain: 'pubmed.ncbi.nlm.nih.gov', url: 'https://pubmed.ncbi.nlm.nih.gov', icon: '🏥', reason: 'Biomedical literature' },
    ],
    design: [
      { name: 'Dribbble', domain: 'dribbble.com', url: 'https://dribbble.com', icon: '🎨', reason: 'Design inspiration and community' },
      { name: 'Figma Community', domain: 'figma.com/community', url: 'https://figma.com/community', icon: '✏️', reason: 'Free design templates and plugins' },
      { name: 'Awwwards', domain: 'awwwards.com', url: 'https://awwwards.com', icon: '🏆', reason: 'Award-winning web design showcase' },
      { name: 'Behance', domain: 'behance.net', url: 'https://behance.net', icon: '🖼️', reason: 'Creative portfolios and projects' },
    ],
    commerce: [
      { name: 'TrustPilot', domain: 'trustpilot.com', url: 'https://trustpilot.com', icon: '⭐', reason: 'Consumer reviews and ratings' },
      { name: 'Better Business Bureau', domain: 'bbb.org', url: 'https://bbb.org', icon: '🏛️', reason: 'Business ratings and complaints' },
      { name: 'Consumer Reports', domain: 'consumerreports.org', url: 'https://consumerreports.org', icon: '📊', reason: 'Independent product testing' },
    ],
    documentation: [
      { name: 'DevDocs', domain: 'devdocs.io', url: 'https://devdocs.io', icon: '📖', reason: 'Unified API documentation browser' },
      { name: 'Read the Docs', domain: 'readthedocs.org', url: 'https://readthedocs.org', icon: '📗', reason: 'Technical documentation hosting' },
    ],
    travel: [
      { name: 'TripAdvisor', domain: 'tripadvisor.com', url: 'https://tripadvisor.com', icon: '✈️', reason: 'Traveler reviews and recommendations' },
      { name: 'Google Maps', domain: 'google.com/maps', url: 'https://google.com/maps', icon: '🗺️', reason: 'Maps and local business info' },
      { name: 'Lonely Planet', domain: 'lonelyplanet.com', url: 'https://lonelyplanet.com', icon: '🌍', reason: 'Travel guides and advice' },
    ],
    general: [
      { name: 'Wikipedia', domain: 'wikipedia.org', url: 'https://wikipedia.org', icon: '📕', reason: 'General encyclopedia reference' },
      { name: 'Google', domain: 'google.com', url: 'https://google.com', icon: '🔍', reason: 'Web search for additional info' },
    ]
  };

  const ResourceProvider = {
    getResources(pageCategory, question) {
      const cat = pageCategory || 'general';
      const resources = RESOURCE_LIBRARY[cat] || RESOURCE_LIBRARY.general;
      // Also add general resources if not already general
      const extras = cat !== 'general' ? RESOURCE_LIBRARY.general : [];
      return [...resources, ...extras].slice(0, 5);
    }
  };

  // ============================================================
  // RESEARCH PROVIDER (Mock)
  // ============================================================
  const ResearchProvider = {
    async research(question, pageContext) {
      // Simulate research delay
      await new Promise(r => setTimeout(r, 1500));
      const title = pageContext?.title || 'this topic';
      const domain = pageContext?.domain || 'website';
      return {
        findings: [
          {
            type: 'CLAIM',
            text: `Analysis of "${title}" indicates strong alignment with current industry best practices.`,
            confidence: 'HIGH',
            score: 86,
            source: { name: `${domain} Documentation`, domain: domain, url: pageContext?.url || '#' },
            freshness: 'Updated recently'
          },
          {
            type: 'DATA POINT',
            text: `Multiple independent sources confirm the core information presented on this page.`,
            confidence: 'HIGH',
            score: 82,
            source: { name: 'Industry Analysis Report', domain: 'reports.industry.org', url: '#' },
            freshness: 'Published within last 6 months'
          },
          {
            type: 'CONTEXT',
            text: `Some implementation details may vary based on specific version or configuration used.`,
            confidence: 'MEDIUM',
            score: 68,
            source: { name: 'Technical Review', domain: 'tech-review.net', url: '#' },
            freshness: 'Verified within last year'
          }
        ],
        summary: `Research on "${question}" found 3 relevant sources with high overall confidence. The information on this page appears accurate and current.`,
        contradictions: [],
        overallConfidence: 79
      };
    }
  };

  return { VideoProvider, ResourceProvider, ResearchProvider, detectTopics };
})();
