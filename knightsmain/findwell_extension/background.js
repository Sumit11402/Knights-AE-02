/* background.js - FindWell Background Service Worker */

chrome.runtime.onInstalled.addListener(() => {
  // Context menu for selected text
  chrome.contextMenus.create({
    id: "researchSelectedText",
    title: "Research with FindWell",
    contexts: ["selection"]
  });

  // Context menu for full page
  chrome.contextMenus.create({
    id: "analyzeCurrentPage",
    title: "Analyze page with FindWell",
    contexts: ["page"]
  });
});

chrome.contextMenus.onClicked.addListener((info, tab) => {
  if (info.menuItemId === "researchSelectedText" && info.selectionText) {
    chrome.storage.local.set({
      pendingSelectionText: info.selectionText,
      pendingSourceUrl: tab.url || info.pageUrl
    }, () => {
      openPopup();
    });
  } else if (info.menuItemId === "analyzeCurrentPage") {
    openPopup();
  }
});

function openPopup() {
  if (chrome.action && typeof chrome.action.openPopup === 'function') {
    chrome.action.openPopup();
  } else {
    chrome.action.setBadgeText({ text: "●" });
    chrome.action.setBadgeBackgroundColor({ color: "#124343" });
  }
}

// Handle message requests from popup (e.g. screenshot capture)
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.action === 'captureVisibleTab') {
    chrome.tabs.captureVisibleTab(null, { format: 'png' }, (dataUrl) => {
      if (chrome.runtime.lastError) {
        sendResponse({ error: chrome.runtime.lastError.message });
      } else {
        sendResponse({ screenshotUrl: dataUrl });
      }
    });
    return true; // Keep message channel open for async response
  }
});
