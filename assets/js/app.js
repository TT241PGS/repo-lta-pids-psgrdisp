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
import { tns } from "tiny-slider/src/tiny-slider";

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

// Date Time component start

function setDateTime() {
  const now = new Date();

  const day = now.toLocaleString("en-SG", { weekday: "long" });

  const date = now.toLocaleString("en-SG", {
    year: "numeric",
    month: "long",
    day: "numeric"
  });

  const time = now.toLocaleTimeString("en-US", {
    hour: "numeric",
    minute: "numeric",
    hour12: false
  });

  const dayNode = document.querySelector("#day");
  const dateNode = document.querySelector("#date");
  const timeNode = document.querySelector("#time");
  if (dayNode && dateNode && timeNode) {
    dayNode.innerHTML = day;
    dateNode.innerHTML = date;
    timeNode.innerHTML = time;
  }
}

function refreshDateTime() {
  setInterval(() => {
    setDateTime();
  }, 100);
}

function playMessages() {
  setInterval(() => {
    const nextSlides = document.querySelector(".message-slides");
    if (
      (nextSlides && !messagesSlider) ||
      currentMessagesSlides !== nextSlides
    ) {
      nextSlides.classList.remove("hidden");
      messagesSlider = tns({
        container: ".message-slides",
        controls: false,
        speed: 500,
        autoplay: true,
        autoplayButtonOutput: false,
        autoplayTimeout: 2000
      });
      currentMessagesSlides = nextSlides;
    }
  }, 100);
}

function playBusStopPredictions() {
  setInterval(() => {
    const nextSlides = document.querySelector(".bus-stop-predictions");
    if (
      (nextSlides && !predictionsSlider) ||
      currentPredictionsSlides !== nextSlides
    ) {
      nextSlides.classList.remove("hidden");
      predictionsSlider = tns({
        container: ".bus-stop-predictions",
        controls: false,
        speed: 500,
        autoplay: true,
        autoplayButtonOutput: false,
        autoplayTimeout: 5000
      });
      currentPredictionsSlides = nextSlides;
    }
  }, 100);
}

onDocReady(refreshDateTime);
// Date Time component  end

// Register sliders
onDocReady(playMessages);
onDocReady(playBusStopPredictions);

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
