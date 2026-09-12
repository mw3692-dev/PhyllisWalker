/* Google Analytics 4 for jhilburnfrisco.thestar.biz
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * TO SWITCH THIS ON: paste the Measurement ID on the next line. Nothing else.
 * ─────────────────────────────────────────────────────────────────────────────
 */
var GA_MEASUREMENT_ID = ""; // e.g. "G-ABCD123456"

/* Until that ID is filled in, this file does nothing at all: no script is
 * fetched, no cookie is set, and the privacy policy stays accurate. That is
 * deliberate — the policy discloses analytics as active, so an empty ID is the
 * safe state rather than a broken tag.
 *
 * WHAT IT MEASURES
 *
 * Pageviews are the easy part. The valuable part is the last measurable step
 * before a booking. The booking form itself lives on GHL's domain
 * (api.leadconnectorhq.com), which we cannot add analytics to, so a completed
 * booking is invisible to GA. What we CAN see is the click that leaves for it,
 * so `book_click` is the conversion proxy — and it carries which appointment
 * type was chosen, which is the interesting dimension: a 60-minute New Client
 * click is worth far more than a 30-minute delivery pickup.
 *
 * It also forwards any utm_* parameters from the page onto the booking URL, so
 * a click that arrived from the fall email is still attributable once it lands
 * in GHL. Without that the campaign attribution dies at the domain boundary.
 *
 * Phone and email taps are tracked too. For a business where most conversions
 * happen by voice, a tel: tap is a stronger buying signal than any page depth.
 */

(function () {
  "use strict";

  var VALID = /^G-[A-Z0-9]{6,}$/i.test(GA_MEASUREMENT_ID);
  if (!VALID) return;

  // Honour Do Not Track. The privacy policy takes a restrained line on
  // tracking, and quietly ignoring DNT would not match it.
  if (navigator.doNotTrack === "1" || window.doNotTrack === "1") return;

  // Which calendar is which, so events say "new-client" rather than an opaque id.
  var CALENDARS = {
    "1r7RfVTwjUwOi7jjnGLh": { name: "new-client", minutes: 60 },
    swgPCbWxHMigGhBMIDqN: { name: "studio-appointment", minutes: 45 },
    VGdTa2UbJAAd7Xv4FQkZ: { name: "delivery-pickup", minutes: 30 }
  };

  window.dataLayer = window.dataLayer || [];
  function gtag() { window.dataLayer.push(arguments); }
  window.gtag = gtag;

  var s = document.createElement("script");
  s.async = true;
  s.src = "https://www.googletagmanager.com/gtag/js?id=" + encodeURIComponent(GA_MEASUREMENT_ID);
  document.head.appendChild(s);

  gtag("js", new Date());
  gtag("config", GA_MEASUREMENT_ID, { anonymize_ip: true });

  /* ---- carry campaign attribution across to GHL ---- */

  function currentUtms() {
    var out = {};
    try {
      new URLSearchParams(window.location.search).forEach(function (v, k) {
        if (k.toLowerCase().indexOf("utm_") === 0) out[k] = v;
      });
    } catch (e) { /* old browser; attribution is a nice-to-have */ }
    return out;
  }

  function withUtms(href, utms) {
    var keys = Object.keys(utms);
    if (!keys.length) return href;
    try {
      var u = new URL(href);
      keys.forEach(function (k) { if (!u.searchParams.has(k)) u.searchParams.set(k, utms[k]); });
      return u.toString();
    } catch (e) { return href; }
  }

  function calendarFrom(href) {
    for (var id in CALENDARS) {
      if (href.indexOf(id) !== -1) return CALENDARS[id];
    }
    return null;
  }

  document.addEventListener("click", function (ev) {
    var a = ev.target && ev.target.closest ? ev.target.closest("a[href]") : null;
    if (!a) return;
    var href = a.getAttribute("href") || "";

    if (href.indexOf("tel:") === 0) {
      gtag("event", "phone_click", { phone: href.replace("tel:", "") });
      return;
    }
    if (href.indexOf("mailto:") === 0) {
      gtag("event", "email_click", {});
      return;
    }

    var cal = calendarFrom(href);
    if (cal) {
      gtag("event", "book_click", {
        appointment_type: cal.name,
        duration_minutes: cal.minutes,
        page: window.location.pathname
      });
      // Pass the campaign through to the booking widget so the source is not
      // lost when the visitor crosses onto GHL's domain.
      var carried = withUtms(href, currentUtms());
      if (carried !== href) a.setAttribute("href", carried);
      return;
    }

    // Anything else leaving the site.
    if (/^https?:\/\//i.test(href) && href.indexOf(window.location.hostname) === -1) {
      gtag("event", "outbound_click", { destination: href });
    }
  }, true);
})();
