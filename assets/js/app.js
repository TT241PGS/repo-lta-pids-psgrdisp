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

  document.querySelector("#day").innerHTML = day;
  document.querySelector("#date").innerHTML = date;
  document.querySelector("#time").innerHTML = time;
}

setDateTime();

setInterval(() => {
  setDateTime();
}, 100);
// Date Time component  end
