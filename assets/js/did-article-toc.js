/* ==========================================================================
   Data Inside Data™ LLC
   File: did-article-toc.js
   Introduced: November 2026

   Purpose:
   Coordinates DID's sticky masthead with Minimal Mistakes' article TOC.
   Measures the rendered masthead height, positions the TOC beneath it,
   preserves heading visibility, and keeps TOC highlighting synchronized
   with the visible article section.

   Part of:
   Data Inside Data™ v3 UI System
   ========================================================================== */

document.addEventListener("DOMContentLoaded", () => {
  const article = document.querySelector(".did-article");
  const masthead = document.querySelector(".masthead");
  const toc = document.querySelector("nav.toc");

  if (!article || !masthead || !toc) {
    return;
  }

  const tocLinks = Array.from(
    toc.querySelectorAll('a[href^="#"]')
  );

  if (!tocLinks.length) {
    return;
  }

  const prefersReducedMotion = window.matchMedia(
    "(prefers-reduced-motion: reduce)"
  ).matches;

  const stickyGap = 16;


  /* ------------------------------------------------------------------------
     Shared sticky offset
     ------------------------------------------------------------------------ */

  const getStickyOffset = () =>
    masthead.getBoundingClientRect().height + stickyGap;


  const updateStickyOffset = () => {
    document.documentElement.style.setProperty(
      "--did-sticky-offset",
      `${getStickyOffset()}px`
    );
  };


  /* ------------------------------------------------------------------------
     Map TOC links to their article headings
     ------------------------------------------------------------------------ */

  const sections = tocLinks
    .map((link) => {
      const id = decodeURIComponent(link.hash.slice(1));
      const heading = document.getElementById(id);

      return heading ? { link, heading } : null;
    })
    .filter(Boolean);


  /* ------------------------------------------------------------------------
     Keep TOC active state aligned with the visible article section
     ------------------------------------------------------------------------ */

  const updateActiveSection = () => {
    const activationLine = getStickyOffset() + 4;

    let current = null;

    sections.forEach((section) => {
      if (
        section.heading.getBoundingClientRect().top <= activationLine
      ) {
        current = section;
      }
    });

    if (!current) {
      current = sections[0];
    }

    toc.querySelectorAll("li.active").forEach((item) => {
      item.classList.remove("active");
    });

    if (current) {
      current.link.closest("li")?.classList.add("active");
    }
  };


  /* ------------------------------------------------------------------------
     DID-aware TOC navigation

     Override MM's fixed 20px scroll offset for article TOC links so headings
     land directly beneath the sticky DID masthead.
     ------------------------------------------------------------------------ */

  toc.addEventListener(
    "click",
    (event) => {
      const link = event.target.closest('a[href^="#"]');

      if (!link) {
        return;
      }

      const id = decodeURIComponent(link.hash.slice(1));
      const heading = document.getElementById(id);

      if (!heading) {
        return;
      }

      event.preventDefault();
      event.stopPropagation();

      const targetTop =
        heading.getBoundingClientRect().top +
        window.scrollY -
        getStickyOffset();

      window.scrollTo({
        top: targetTop,
        behavior: prefersReducedMotion ? "auto" : "smooth"
      });

      history.replaceState(null, "", link.hash);
    },
    true
  );


  /* ------------------------------------------------------------------------
     Scroll / resize synchronization
     ------------------------------------------------------------------------ */

  let ticking = false;

  const queueUpdate = () => {
    if (ticking) {
      return;
    }

    ticking = true;

    requestAnimationFrame(() => {
      updateStickyOffset();
      updateActiveSection();

      ticking = false;
    });
  };


  updateStickyOffset();
  updateActiveSection();

  window.addEventListener("scroll", queueUpdate, { passive: true });
  window.addEventListener("resize", queueUpdate);


  /* Recalculate if responsive masthead content changes its rendered height. */
  if ("ResizeObserver" in window) {
    const mastheadObserver = new ResizeObserver(queueUpdate);
    mastheadObserver.observe(masthead);
  }
});