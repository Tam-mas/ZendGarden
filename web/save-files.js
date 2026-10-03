/* Settings file picker. Save validation and replacement stay inside the game;
   this bridge only reads a file explicitly selected on the player's device. */
(() => {
  const MAX_BYTES = 4 * 1024 * 1024;
  let active;
  window.ZendSaveFiles = {
    cancel() {
      if (active) active.remove();
      active = null;
    },
    choose(callback) {
      this.cancel();
      const input = document.createElement('input');
      input.type = 'file';
      input.accept = '.json,application/json';
      input.hidden = true;
      input.setAttribute('aria-label', 'Choose a garden save file');
      document.body.appendChild(input);
      active = input;
      const done = (text = '', name = '', error = '') => {
        if (active !== input) return;
        this.cancel();
        callback(text, name, error);
      };
      input.addEventListener('cancel', () => done('', '', 'cancelled'), { once: true });
      input.addEventListener('change', async () => {
        const file = input.files?.[0];
        if (!file) { done('', '', 'cancelled'); return; }
        if (!file.size || file.size > MAX_BYTES) {
          done('', '', 'Choose a complete garden JSON file smaller than 4 MB.');
          return;
        }
        try {
          const text = new TextDecoder('utf-8', { fatal: true }).decode(await file.arrayBuffer());
          done(text, file.name);
        } catch {
          done('', '', 'This file could not be read. Choose a garden JSON save.');
        }
      }, { once: true });
      input.click();
    },
  };
})();
