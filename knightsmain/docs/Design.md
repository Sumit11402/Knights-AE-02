# Visual Design & UI System — FindWell

## 1. UI Tone & Design Philosophy
**Tone**: Technical, sleek, authoritative, and transparent.
The UI should feel like a high-tech intelligence workstation—combining deep dark backgrounds, subtle glassmorphism layers, vibrant neon accents, and crystal-clear typography. It prioritizes inspectability, showing realtime agent reasoning, evidence provenance, and security boundaries without visual clutter.

---

## 2. Color Palette

```
+-----------------------------------------------------------------------+
|  Primary Background:    Deep Navy        #0A0E27                      |
|  Surface Layers:        Dark Card        #161B4A (Opacity: 0.6-0.8)   |
|  Card Borders:          Subtle Indigo    #2A2F6A (Opacity: 0.5)       |
|                                                                       |
|  Accent Gradient:       Electric Purple  #7C3AED                      |
|                         Vibrant Blue     #2563EB                      |
|                         Cyan Highlight   #06B6D4                      |
|                                                                       |
|  Status Colors:         Success Green    #10B981                      |
|                         Warning Amber    #F59E0B                      |
|                         Security Red     #EF4444                      |
|                         Info Blue        #3B82F6                      |
+-----------------------------------------------------------------------+
```

---

## 3. Typography & Micro-Interactions

* **Primary Font**: `Inter` — for UI labels, headers, and body text. Clean, highly legible at small sizes.
* **Code & Monospace Font**: `JetBrains Mono` — for trace logs, raw evidence passages, BibTeX entries, and code execution outputs.
* **Micro-Interactions**:
  * Shimmer loading sweeps for background retrieval tasks.
  * Pulsing status indicators for active sandboxed execution sessions.
  * Smooth page transition animations (`GoRouter` slide/fade transitions).
  * Glowing glassmorphism hover effects on project and evidence cards.

---

## 4. Key UI Screen Layouts

1. **Dashboard**: High-level project grid, current strategy version indicator, recent research activity stream.
2. **Research Planner & DAG View**: Interactive node graph displaying subquestion progress, confidence scores, and source policies.
3. **Trace & Execution Console**: Split view showing live agent tool calls, container terminal stdout/stderr, and untrusted input defense logs.
4. **Evidence & Citation Explorer**: Interactive graph connecting research claims directly to highlighted source passages and BibTeX metadata.
5. **Self-Evolution Workshop**: Side-by-side comparison of proposed strategy prompts vs. baseline, accompanied by held-out task benchmark metrics.
