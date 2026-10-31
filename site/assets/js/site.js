(function () {
  "use strict";

  var doc = document;
  var root = doc.documentElement;
  var header = doc.querySelector("[data-head]");
  var progress = doc.querySelector("[data-progress]");
  var percent = doc.querySelector("[data-scroll-percent]");
  var navLinks = Array.prototype.slice.call(doc.querySelectorAll(".desk-nav a[href^='#']"));
  var sections = navLinks
    .map(function (link) {
      var id = link.getAttribute("href").slice(1);
      var section = doc.getElementById(id);
      return section ? { id: id, link: link, section: section } : null;
    })
    .filter(Boolean);
  var ticking = false;

  function setActiveNav(id) {
    navLinks.forEach(function (link) {
      var active = link.getAttribute("href") === "#" + id;
      link.classList.toggle("is-active", active);
      if (active) {
        link.setAttribute("aria-current", "location");
      } else {
        link.removeAttribute("aria-current");
      }
    });
  }

  function updateScrollState() {
    var scrollY = window.scrollY || window.pageYOffset || 0;
    var height = doc.documentElement.scrollHeight - window.innerHeight;
    var ratio = height > 0 ? Math.min(1, Math.max(0, scrollY / height)) : 0;

    if (header) {
      header.classList.toggle("is-scrolled", scrollY > 12);
    }
    if (progress) {
      progress.style.transform = "scaleX(" + ratio + ")";
    }
    if (percent) {
      percent.textContent = String(Math.round(ratio * 100)).padStart(3, "0");
    }

    if (sections.length) {
      var marker = scrollY + Math.min(window.innerHeight * 0.36, 340);
      var current = "";
      sections.forEach(function (entry) {
        if (entry.section.offsetTop <= marker) {
          current = entry.id;
        }
      });
      setActiveNav(current);
    }
    ticking = false;
  }

  function requestScrollState() {
    if (!ticking) {
      ticking = true;
      window.requestAnimationFrame(updateScrollState);
    }
  }

  window.addEventListener("scroll", requestScrollState, { passive: true });
  window.addEventListener("resize", requestScrollState);
  updateScrollState();

  // Menu dialog --------------------------------------------------------------
  var menu = doc.querySelector("[data-menu]");
  var menuOpen = doc.querySelector("[data-menu-open]");
  var menuClose = doc.querySelector("[data-menu-close]");

  function openMenu() {
    if (!menu || !menu.showModal) return;
    if (!menu.open) menu.showModal();
    if (menuOpen) menuOpen.setAttribute("aria-expanded", "true");
    if (menuClose) menuClose.focus();
  }

  function closeMenu() {
    if (!menu) return;
    if (menu.open) menu.close();
    if (menuOpen) {
      menuOpen.setAttribute("aria-expanded", "false");
      menuOpen.focus();
    }
  }

  if (menuOpen) {
    menuOpen.setAttribute("aria-expanded", "false");
    menuOpen.addEventListener("click", openMenu);
  }
  if (menuClose) menuClose.addEventListener("click", closeMenu);
  if (menu) {
    menu.addEventListener("click", function (event) {
      if (event.target === menu) closeMenu();
    });
    menu.addEventListener("close", function () {
      if (menuOpen) {
        menuOpen.setAttribute("aria-expanded", "false");
        menuOpen.focus();
      }
    });
    menu.querySelectorAll("a[href^='#']").forEach(function (link) {
      link.addEventListener("click", function () {
        if (menu.open) menu.close();
      });
    });
  }

  // Reveal on scroll ---------------------------------------------------------
  var reveals = Array.prototype.slice.call(doc.querySelectorAll("[data-reveal]"));
  if ("IntersectionObserver" in window) {
    var revealObserver = new IntersectionObserver(
      function (entries) {
        entries.forEach(function (entry) {
          if (entry.isIntersecting) {
            entry.target.classList.add("is-visible");
            revealObserver.unobserve(entry.target);
          }
        });
      },
      { threshold: 0.12, rootMargin: "0px 0px -8% 0px" }
    );
    reveals.forEach(function (element) {
      revealObserver.observe(element);
    });
  } else {
    reveals.forEach(function (element) {
      element.classList.add("is-visible");
    });
  }

  // Gallery ------------------------------------------------------------------
  var gallery = doc.querySelector("[data-gallery]");
  if (gallery) {
    var tabs = Array.prototype.slice.call(gallery.querySelectorAll("[data-target]"));
    var panels = Array.prototype.slice.call(gallery.querySelectorAll("[data-panel]"));
    var count = gallery.querySelector("[data-gallery-count]");
    var caption = gallery.querySelector("[data-gallery-caption]");

    function activateTab(tab) {
      if (!tab) return;
      var target = tab.getAttribute("data-target");
      tabs.forEach(function (item) {
        var active = item === tab;
        item.classList.toggle("is-active", active);
        item.setAttribute("aria-pressed", active ? "true" : "false");
      });
      panels.forEach(function (panel) {
        var active = panel.id === target;
        panel.classList.toggle("is-active", active);
        panel.setAttribute("aria-hidden", active ? "false" : "true");
      });
      if (count) {
        var index = tabs.indexOf(tab) + 1;
        count.textContent = String(index).padStart(2, "0");
      }
      if (caption) {
        caption.textContent = tab.getAttribute("data-caption") || "";
      }
    }

    tabs.forEach(function (tab, index) {
      tab.addEventListener("click", function () {
        activateTab(tab);
      });
      tab.addEventListener("keydown", function (event) {
        var next = null;
        if (event.key === "ArrowDown" || event.key === "ArrowLeft") {
          next = tabs[(index + 1) % tabs.length];
        } else if (event.key === "ArrowUp" || event.key === "ArrowRight") {
          next = tabs[(index - 1 + tabs.length) % tabs.length];
        } else if (event.key === "Home") {
          next = tabs[0];
        } else if (event.key === "End") {
          next = tabs[tabs.length - 1];
        }
        if (next) {
          event.preventDefault();
          next.focus();
          activateTab(next);
        }
      });
    });
  }

  // Set-row demo -------------------------------------------------------------
  var demo = doc.querySelector("[data-set-demo]");
  var demoButton = doc.querySelector("[data-set-check]");
  if (demo && demoButton) {
    demoButton.addEventListener("click", function () {
      var saved = !demo.classList.contains("is-saved");
      demo.classList.toggle("is-saved", saved);
      demoButton.setAttribute("aria-pressed", saved ? "true" : "false");
      demoButton.setAttribute(
        "aria-label",
        saved ? "بازنشانی نمونهٔ ست" : "ثبت نمونهٔ ست"
      );
    });
  }

  // Copy the checksum --------------------------------------------------------
  var copyButtons = Array.prototype.slice.call(doc.querySelectorAll("[data-copy]"));
  copyButtons.forEach(function (button) {
    var label = button.querySelector("[data-copy-label]");
    var original = label ? label.textContent : "کپی";
    var resetTimer = null;

    function markCopied(ok) {
      if (!label) return;
      label.textContent = ok ? "کپی شد" : "کپی نشد";
      window.clearTimeout(resetTimer);
      resetTimer = window.setTimeout(function () {
        label.textContent = original;
      }, 2200);
    }

    function fallbackCopy(value) {
      var area = doc.createElement("textarea");
      area.value = value;
      area.setAttribute("readonly", "");
      area.style.position = "fixed";
      area.style.opacity = "0";
      area.style.pointerEvents = "none";
      doc.body.appendChild(area);
      area.select();
      var ok = false;
      try {
        ok = doc.execCommand("copy");
      } catch (error) {
        ok = false;
      }
      doc.body.removeChild(area);
      markCopied(ok);
    }

    button.addEventListener("click", function () {
      var value = button.getAttribute("data-copy") || "";
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(value).then(
          function () {
            markCopied(true);
          },
          function () {
            fallbackCopy(value);
          }
        );
      } else {
        fallbackCopy(value);
      }
    });
  });
})();
