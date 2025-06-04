# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...


allow pasting

and press Enter.

Paste the snippet below into the console and hit Enter:
(function(){
  const COOLDOWN_MS = 2500;
  let lastClick = 0;

  function clickIfFound() {
    const now = Date.now();
    if (now - lastClick < COOLDOWN_MS) return;

    // Continue
    const continueBtn = Array.from(
      document.querySelectorAll('a.monaco-button[role="button"], button.monaco-button')
    ).find(el => /continue/i.test(el.textContent?.trim()));
    if (continueBtn) {
      continueBtn.click();
      lastClick = now;
      console.log('[auto] Clicked Continue');
    }

    // Keep
    const keepBtn = Array.from(
      document.querySelectorAll('a.action-label[role="button"]')
    ).find(el => /^keep$/i.test(el.textContent?.trim()));
    if (keepBtn) {
      keepBtn.click();
      lastClick = now;
      console.log('[auto] Clicked Keep');
    }
  }

  const intervalId = setInterval(clickIfFound, 1000);
  const observer   = new MutationObserver(clickIfFound);
  observer.observe(document.body, { childList: true, subtree: true });

  window.stopAutoContinue = () => {
    clearInterval(intervalId);
    observer.disconnect();
    console.log('[auto] stopped.');
  };
})();
Usage

Once pasted, the script immediately begins watching for and clicking the Continue button whenever it appears.

You’ll see logs in your console each time it clicks.


Stopping
To halt the auto‑clicker at any time, switch to the console and run:

window.stopAutoContinue();
