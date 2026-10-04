// Keep the browser's install prompt so the app can offer "Install" at a
// good moment (it fires once, often before Flutter has started).
window.sbInstallPrompt = null;
window.addEventListener('beforeinstallprompt', function (e) {
  e.preventDefault();
  window.sbInstallPrompt = e;
  window.dispatchEvent(new Event('sbinstallchange'));
});
window.addEventListener('appinstalled', function () {
  window.sbInstallPrompt = null;
  window.sbInstalled = true;
  window.dispatchEvent(new Event('sbinstallchange'));
});
