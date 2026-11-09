(() => {
  const YEAR = document.getElementById("y");
  if (YEAR) YEAR.textContent = String(new Date().getFullYear());

  // —— Nav ——
  const toggle = document.querySelector("[data-nav-toggle]");
  const drawer = document.querySelector("[data-nav-drawer]");
  const subToggle = document.querySelector("[data-sub-toggle]");
  const subPanel = document.querySelector("[data-sub-panel]");
  const msubToggle = document.querySelector("[data-msub-toggle]");
  const msub = document.querySelector("[data-msub]");

  const setSub = (open) => {
    if (!subToggle || !subPanel) return;
    subToggle.setAttribute("aria-expanded", open ? "true" : "false");
    subPanel.hidden = !open;
    const root = subToggle.closest(".has-sub");
    if (root) root.classList.toggle("is-open", open);
  };

  const setMsub = (open) => {
    if (!msubToggle || !msub) return;
    msubToggle.setAttribute("aria-expanded", open ? "true" : "false");
    msubToggle.textContent = open ? "−" : "+";
    msub.hidden = !open;
  };

  if (toggle && drawer) {
    const setOpen = (open) => {
      toggle.setAttribute("aria-expanded", open ? "true" : "false");
      drawer.classList.toggle("is-open", open);
      document.body.classList.toggle("nav-open", open);
      if (!open) setMsub(false);
    };

    toggle.addEventListener("click", () => {
      setOpen(toggle.getAttribute("aria-expanded") !== "true");
    });

    drawer.querySelectorAll("a").forEach((link) => {
      link.addEventListener("click", () => setOpen(false));
    });

    document.addEventListener("keydown", (e) => {
      if (e.key === "Escape") {
        setOpen(false);
        setSub(false);
      }
    });
  }

  if (subToggle && subPanel) {
    const subRoot = subToggle.closest(".has-sub");
    const header = subToggle.closest(".site-header");
    let closeTimer = 0;
    const canHover =
      window.matchMedia("(hover: hover) and (pointer: fine)").matches;

    const insideMega = (node) =>
      Boolean(
        node &&
          ((subRoot && subRoot.contains(node)) ||
            subPanel.contains(node) ||
            (node === subToggle))
      );

    const openSub = () => {
      window.clearTimeout(closeTimer);
      setSub(true);
      if (subRoot) subRoot.classList.add("is-open");
      if (header) header.classList.add("is-mega-open");
    };
    const closeSub = () => {
      setSub(false);
      if (subRoot) subRoot.classList.remove("is-open");
      if (header) header.classList.remove("is-mega-open");
    };
    const scheduleClose = () => {
      window.clearTimeout(closeTimer);
      closeTimer = window.setTimeout(closeSub, 180);
    };

    // Desktop: hover en trigger o en el panel (el panel ya no está dentro de .has-sub).
    if (canHover && subRoot) {
      subRoot.addEventListener("mouseenter", openSub);
      subRoot.addEventListener("mouseleave", (e) => {
        if (!insideMega(e.relatedTarget)) scheduleClose();
      });
      subPanel.addEventListener("mouseenter", openSub);
      subPanel.addEventListener("mouseleave", (e) => {
        if (!insideMega(e.relatedTarget)) scheduleClose();
      });
      subRoot.addEventListener("focusin", openSub);
      subPanel.addEventListener("focusin", openSub);
      const onFocusOut = (e) => {
        if (!insideMega(e.relatedTarget)) scheduleClose();
      };
      subRoot.addEventListener("focusout", onFocusOut);
      subPanel.addEventListener("focusout", onFocusOut);
    }

    subToggle.addEventListener("click", (e) => {
      e.preventDefault();
      e.stopPropagation();
      if (subPanel.hidden) openSub();
      else closeSub();
    });
    document.addEventListener("click", (e) => {
      if (!insideMega(e.target)) closeSub();
    });
  }

  if (msubToggle && msub) {
    msubToggle.addEventListener("click", () => {
      setMsub(msub.hidden);
    });
  }

  // —— Scroll reveal (respects reduced motion) ——
  const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  const revealItems = document.querySelectorAll("[data-reveal]");
  const markVisible = (el) => el.classList.add("is-visible");

  if (reduceMotion || !("IntersectionObserver" in window)) {
    revealItems.forEach(markVisible);
  } else {
    const io = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            markVisible(entry.target);
            io.unobserve(entry.target);
          }
        });
      },
      { rootMargin: "0px 0px -5% 0px", threshold: 0.08 }
    );
    revealItems.forEach((el, i) => {
      if (el.classList.contains("is-visible")) {
        io.unobserve(el);
        return;
      }
      el.style.setProperty("--reveal-delay", `${Math.min(i % 6, 5) * 60}ms`);
      io.observe(el);
    });
    // Above-the-fold safety: mark anything already in view on the next frame
    requestAnimationFrame(() => {
      revealItems.forEach((el) => {
        if (el.classList.contains("is-visible")) return;
        const rect = el.getBoundingClientRect();
        if (rect.top < window.innerHeight * 0.92 && rect.bottom > 0) {
          markVisible(el);
          io.unobserve(el);
        }
      });
    });
  }

  // —— Cookie consent ——
  const STORAGE_KEY = "repera_cookie_prefs_v1";
  const banner = document.querySelector("[data-cookie-banner]");
  const panel = document.querySelector("[data-cookie-panel]");
  const openers = document.querySelectorAll("[data-cookie-open]");

  const defaultPrefs = () => ({
    necessary: true,
    analytics: false,
    updatedAt: new Date().toISOString(),
  });

  const readPrefs = () => {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (!raw) return null;
      return { ...defaultPrefs(), ...JSON.parse(raw) };
    } catch {
      return null;
    }
  };

  // GA4 (mismo proyecto Firebase que la app: repera-mv). Solo tras opt-in de cookies.
  const GA4_ID = (document.documentElement.dataset.ga4 || "").trim();
  let ga4ScriptLoaded = false;

  const ensureGtag = () => {
    window.dataLayer = window.dataLayer || [];
    if (typeof window.gtag !== "function") {
      window.gtag = function gtag() {
        window.dataLayer.push(arguments);
      };
    }
  };

  const loadAnalytics = () => {
    if (!GA4_ID) return;
    ensureGtag();
    window.gtag("consent", "update", { analytics_storage: "granted" });
    if (!ga4ScriptLoaded) {
      ga4ScriptLoaded = true;
      const script = document.createElement("script");
      script.async = true;
      script.src = `https://www.googletagmanager.com/gtag/js?id=${encodeURIComponent(GA4_ID)}`;
      document.head.appendChild(script);
      window.gtag("js", new Date());
      window.gtag("config", GA4_ID, {
        anonymize_ip: true,
        send_page_view: true,
        transport_type: "beacon",
      });
    }
  };

  const revokeAnalytics = () => {
    ensureGtag();
    window.gtag("consent", "update", { analytics_storage: "denied" });
  };

  const writePrefs = (prefs) => {
    const next = { ...defaultPrefs(), ...prefs, necessary: true, updatedAt: new Date().toISOString() };
    localStorage.setItem(STORAGE_KEY, JSON.stringify(next));
    document.documentElement.dataset.analytics = next.analytics ? "1" : "0";
    if (next.analytics) loadAnalytics();
    else revokeAnalytics();
    window.dispatchEvent(new CustomEvent("repera:cookie-prefs", { detail: next }));
    return next;
  };

  const hideBanner = () => {
    if (banner) {
      banner.hidden = true;
      banner.setAttribute("aria-hidden", "true");
    }
    document.body.classList.remove("cookie-open");
  };

  const showBanner = () => {
    if (banner) {
      banner.hidden = false;
      banner.setAttribute("aria-hidden", "false");
    }
    document.body.classList.add("cookie-open");
  };

  const syncPanel = (prefs) => {
    if (!panel) return;
    const analytics = panel.querySelector('[name="analytics"]');
    if (analytics) analytics.checked = !!prefs.analytics;
  };

  const existing = readPrefs();
  if (existing) {
    writePrefs(existing);
    hideBanner();
    syncPanel(existing);
  } else {
    showBanner();
    syncPanel(defaultPrefs());
  }

  banner?.querySelector("[data-cookie-accept]")?.addEventListener("click", () => {
    writePrefs({ analytics: true });
    hideBanner();
    if (panel) panel.hidden = true;
  });

  banner?.querySelector("[data-cookie-reject]")?.addEventListener("click", () => {
    writePrefs({ analytics: false });
    hideBanner();
    if (panel) panel.hidden = true;
  });

  banner?.querySelector("[data-cookie-customize]")?.addEventListener("click", () => {
    if (panel) {
      panel.hidden = false;
      panel.querySelector("input,button")?.focus();
    }
  });

  panel?.querySelector("[data-cookie-save]")?.addEventListener("click", () => {
    const analytics = !!panel.querySelector('[name="analytics"]')?.checked;
    writePrefs({ analytics });
    hideBanner();
    panel.hidden = true;
  });

  panel?.querySelector("[data-cookie-close]")?.addEventListener("click", () => {
    panel.hidden = true;
  });

  openers.forEach((btn) => {
    btn.addEventListener("click", (e) => {
      e.preventDefault();
      showBanner();
      if (panel) {
        panel.hidden = false;
        syncPanel(readPrefs() || defaultPrefs());
      }
    });
  });
})();
