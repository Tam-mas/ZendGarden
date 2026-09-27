/* Keep the launch screen and canvas inside Safari's visible browser area. */
(() => {
  const root = document.documentElement;
  const viewport = window.visualViewport;
  function fitScreen() {
    const width = viewport ? viewport.width : window.innerWidth;
    const height = viewport ? viewport.height : window.innerHeight;
    root.style.setProperty('--garden-width', `${Math.round(width)}px`);
    root.style.setProperty('--garden-height', `${Math.round(height)}px`);
    root.style.setProperty('--garden-left', `${viewport ? viewport.offsetLeft : 0}px`);
    root.style.setProperty('--garden-top', `${viewport ? viewport.offsetTop : 0}px`);
  }
  fitScreen();
  window.addEventListener('resize', fitScreen);
  window.addEventListener('orientationchange', fitScreen);
  window.addEventListener('pageshow', fitScreen);
  viewport?.addEventListener('resize', fitScreen);
  viewport?.addEventListener('scroll', fitScreen);

  const button = document.getElementById('fullscreen');
  const note = document.getElementById('fullscreen-note');
  const supported = !!(root.requestFullscreen || root.webkitRequestFullscreen);
  button.hidden = !supported;
  window.zendRequestFullscreen = async () => {
    if (!supported || document.fullscreenElement || document.webkitFullscreenElement) return;
    try {
      const request = root.requestFullscreen || root.webkitRequestFullscreen;
      await request.call(root);
      note.textContent = '';
    } catch (_) {
      note.textContent = 'Fullscreen is unavailable here. The game will still fill the browser window.';
    }
    fitScreen();
  };
  button.addEventListener('click', window.zendRequestFullscreen);
  document.addEventListener('fullscreenchange', fitScreen);
  document.addEventListener('webkitfullscreenchange', fitScreen);
})();
