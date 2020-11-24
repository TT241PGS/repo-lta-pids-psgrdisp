// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.scss";

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
let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken }
});

// Show progress bar on live navigation and form submits
window.addEventListener("phx:page-loading-start", info => NProgress.start());
window.addEventListener("phx:page-loading-stop", info => NProgress.done());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)
window.liveSocket = liveSocket;

function slideInLayouts() {
  setInterval(() => {
    const wrapperHidden = document.querySelector(".full-page-wrapper.hide");
    wrapperHidden && wrapperHidden.classList.remove("hide");
    if (wrapperHidden && wrapperHidden.classList.contains("multi-layout")) {
      // Slide in for multi layout
      wrapperHidden.classList.add("slide-in");
    } else {
      // Fade in for single layout
      wrapperHidden && wrapperHidden.classList.add("fade-in");
    }
  }, 100);
}

// Register sliders
onDocReady(slideInLayouts);

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
