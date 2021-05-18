// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.scss";
import '@fortawesome/fontawesome-free/css/all.css';

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import "phoenix_html";
import { Socket } from "phoenix";
import NProgress from "nprogress";
import { LiveSocket } from "phoenix_live_view";

// messagesSlider init
window.messagesSlider = null;
window.currentMessagesSlides = null;

// predictionsSlider init
window.predictionsSlider = null;
window.currentPredictionsSlides = null;

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");

let Hooks = {};
Hooks.BusStopName = {
  // when component mounts, store the bus stop name in localstorage. To be used by offline.html
  mounted() {
    window.localStorage.setItem('busStopName', this.el.dataset.stopname);
  }
}

let liveSocket = new LiveSocket("/live", Socket, {
  hooks: Hooks,
  params: { _csrf_token: csrfToken }
});

// Show progress bar on live navigation and form submits
window.addEventListener("phx:page-loading-start", info => {
  // When the server completely stops responding or throws any internal error
  if (info.detail && info.detail.kind && info.detail.kind === "error") {
    // Reload is needed to go in offline mode, when the server stops responding
    location.reload();
  } else {
    NProgress.start()
  }
});
window.addEventListener("phx:page-loading-stop", info => NProgress.done());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)
window.liveSocket = liveSocket;

function onDocReady(fn) {
  // see if DOM is already available
  if (
    document.readyState === "complete" ||
    document.readyState === "interactive"
  ) {
    // call on next available tick
    setTimeout(fn, 1);
  } else {
    document.addEventListener("DOMContentLoaded", fn);
  }
}

// When internet connection lost, reload page so that service worker will load offline.html instantly
window.addEventListener('offline', () => {
  location.reload();
});

window.addEventListener("load", () => {
  if ("serviceWorker" in navigator) {
    navigator.serviceWorker.register("/service-worker.js");
    (async () => {
      const registration = await navigator.serviceWorker.ready;
      if ('periodicSync' in registration) {
        try {
          await registration.periodicSync.register('update-offline-page', {
            // An interval of one minute.
            minInterval: 60 * 1000,
          });
        } catch (error) {
          // Periodic background sync cannot be used.
          // Update now
          updateOfflinePage()
        }
      }
    })();
  }

});

window.updateOfflinePage = function () {
  const CACHE_NAME = "offline";
  // Customize this with a different URL if needed.
  const OFFLINE_URL = "offline.html";

  (async () => {
    const cache = await caches.open(CACHE_NAME);
    // Setting {cache: 'reload'} in the new request will ensure that the
    // response isn't fulfilled from the HTTP cache; i.e., it will be from
    // the network.
    await cache.add(new Request(OFFLINE_URL, { cache: "reload" }));
  })()

}
