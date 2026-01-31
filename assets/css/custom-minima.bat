/* ==========================================================================
   DataInsideData — Minima overrides (custom.css)
   Goal: clean, minimal, no duplication, predictable overrides
   Jekyll: 4.4.1 | Ruby: 3.4.8 | Theme: Minima 2.5.2
   ========================================================================== */

/* ==========================================================================
   0) TOKENS + GLOBAL RHYTHM
   ========================================================================== */

:root{
  /* Page tone */
  --did-bg: #f7f9fc;          /* page background (subtle cool white) */
  --did-surface: #eef2ff;     /* surfaces (header bar, cards, footer) */

  /* Text */
  --did-text: #111827;
  --did-muted: #6b7280;

  /* Links / accents */
  --did-primary: #1e40af;
  --did-primary-hover: #1d4ed8;

  /* Header frame */
  --did-pill-outer: #93c5fd;
  --did-pill-inner: #e0f2fe;
  --did-frame-outer: #bfdbfe;

  /* Lines */
  --did-border-soft: #e5e7eb;
}

html, body{
  background: var(--did-bg) !important;
  color: var(--did-text) !important;
}

/* Content rhythm */
.page-content{
  font-size: 0.96rem;
  line-height: 1.65;
  background: transparent !important;
}

main{
  padding-top: 0.25rem;
}

/* Accessibility helper: hide visually, keep for screen readers/SEO */

/* ==========================================================================
  Logo far-left, nav far-right, clean + responsive
   Targets your header.html: .did-brand--logo .did-logo-link .did-logo .site-nav
   ========================================================================== */

/* ---------------------------
   Header (no pill, full width)
---------------------------- */
/* ==========================================================================
   HEADER / NAV — Logo-only, full-bleed, no pill/box (Minima) 
   Targets: .did-brand--logo, .did-logo-link, .did-logo, .site-nav
   ========================================================================== */

/* Make header full-bleed */
.site-header{
  background: var(--did-bg) !important;
  border: 0 !important;
  box-shadow: none !important;
  margin: 0.75rem 0 !important;
  padding: 0.4rem 0 !important;
}

/* Kill Minima's centered container behavior */
.site-header .wrapper{
  max-width: none !important;
  width: 100% !important;
  margin: 0 !important;
  padding: 0 1.25rem !important;
  box-sizing: border-box !important;
}

/* Two-zone layout */
.did-header{
  display: grid !important;
  grid-template-columns: 260px 1fr; /* LEFT box width; tweak */
  align-items: center !important;
  column-gap: 1.25rem !important;
}

/* Left zone stays fixed; doesn't push nav */
.did-header__left{
  display: flex;
  align-items: center;
  min-width: 0;
}

/* Right zone always pins nav to the right */
.did-header__right{
  display: flex;
  justify-content: flex-end;
  align-items: center;
  min-width: 0;
}

/* Logo: scale inside its own box */
.did-logo-link{
  display: inline-flex;
  align-items: center;
  text-decoration: none;
}

.did-logo{
  height: 96px;
  width: 180px;
  object-fit: cover;          /* acts like crop */
  object-position: left center; /* shift the visible area */
  transform: scale(1.15);     /* punch it up a bit */
}


/* Desktop nav row */
@media (min-width: 768px){
  .site-nav .trigger{
    display: flex;
    gap: 1.35rem;
    white-space: nowrap;
    justify-content: flex-end;
  }
}

/* If Minima prints title/tagline anywhere inside header, hide visually */
.site-header .site-title,
.site-header .site-tagline{
  display: none !important;
}

/*================================================================================
==================================================================================*/
/* =========================
   Uncage the logo area (keep nav untouched)
   ========================= */

/* Give the header more vertical room so the logo can breathe */
.site-header{
  padding: 1.05rem 0 !important;  /* was 0.4rem */
}

/* Make the LEFT column slightly wider so the logo can grow without cropping weirdly */
.did-header{
  grid-template-columns: 320px 1fr !important; /* was 260px */
  align-items: center !important;
}

/* Give the left zone a defined height so transform scale doesn't look clipped */
.did-header__left{
  min-height: 140px;              /* key: uncages top/bottom */
}

/* Logo sizing: increase height, keep crop style, and anchor the scale */
.did-logo{
  height: 112px;                  /* was 96px */
  width: 240px;                   /* was 180px */
  object-fit: cover;
  object-position: left center;
  transform: scale(1.10);         /* was 1.15 (safer) */
  transform-origin: left center;  /* prevents “push outward” feel */
}
/*------------------------------------------------------------------------------*/
/* Make header wrapper ignore Minima's centered max-width box */
.site-header .wrapper{
  max-width: none !important;
  margin-left: 0 !important;
  margin-right: 0 !important;
  width: 100% !important;
  padding-left: 1.25rem !important;
  padding-right: 1.25rem !important;
  box-sizing: border-box !important;
}

/* Accessibility: hide sr-only text visually */
.sr-only{
  position: absolute !important;
  width: 1px !important;
  height: 1px !important;
  padding: 0 !important;
  margin: -1px !important;
  overflow: hidden !important;
  clip: rect(0, 0, 0, 0) !important;
  white-space: nowrap !important;
  border: 0 !important;
}

/* =========================================
   FINAL PATCH — nav hard-right + blue links + no logo crop
   Paste at very bottom of custom.css
   ========================================= */

/* Make the right zone truly consume the remaining space */
.did-header__right{
  width: 100% !important;
}

/* Force the nav container + trigger to align to the far right */
.site-nav{
  width: 100% !important;
  display: flex !important;
  justify-content: flex-end !important;
}

.site-nav .trigger{
  margin-left: auto !important;
  justify-content: flex-end !important;
}

/* Restore blue nav links */
.site-nav .page-link{
  color: var(--did-primary) !important;
  font-weight: 700 !important;
  text-decoration: none !important;
}

.site-nav .page-link:hover,
.site-nav .page-link:focus{
  color: var(--did-primary-hover) !important;
}

/* Make the logo big WITHOUT cropping */
.did-logo{
  height: 170px !important;       /* adjust: 120–170 */
  width: 260px !important;        /* gives room for the wide logo */
  object-fit: contain !important; /* KEY: no crop */
  object-position: left center !important;
  transform: none !important;     /* remove scale since we're not cropping */
}

.did-logo{
  height: 64px;
  width: auto;
  object-fit: contain;
}
.brand-hero{
  padding: 3rem 1.25rem 2rem;
  background: var(--did-bg);
}

.brand-hero img{
  max-width: 420px;
  width: 100%;
}

/*-----------------------------------------------------------------------*/
/* Mobile: keep Minima hamburger behavior intact */
@media (max-width: 767px){
  .site-header{
    padding: 0.6rem 0 !important;
  }

  .site-header .wrapper{
    padding: 0 0.95rem !important;
  }

  .did-logo{
    height: 64px;              /* smaller on phones */
  }
}
/* ==========================================================================
   DESKTOP: logo left, nav right
   ========================================================================== */
@media (min-width: 768px){
  .site-header .wrapper{
    display: flex !important;
    align-items: center !important;
    justify-content: space-between !important;
  }

  .did-brand--logo{ flex: 0 0 auto; }

  .site-nav{
    margin-left: auto !important;
    flex: 0 0 auto;
  }

  /* keep link row tight */
  .site-nav .trigger{
    display: flex;
    justify-content: flex-end;
    gap: 1.35rem;
    white-space: nowrap;
  }
}
/* ==========================================================================
   MICRO-MOBILE polish (keep Minima menu behavior)
   ========================================================================== */
/* Mobile: keep Minima hamburger behavior */
@media (max-width: 480px){

  .site-header{
    margin: 0.55rem 0 !important;
    padding: 0.40rem 0 !important;
  }

  .site-header .wrapper{
    padding: 0.45rem 0.85rem !important;
  }

  .did-logo{
    height: 60px;     /* slightly smaller for tiny screens */
    max-height: 60px;
  }
}

/* ==========================================================================
   2) FOOTER (structure + typography)
   ========================================================================== */

.site-footer{
  padding-top: 1rem !important;
  padding-bottom: 1rem !important;
}

.site-footer .footer-heading{
  margin: 0 0 0.75rem;
  font-size: 1.35rem;
  font-weight: 600;
  letter-spacing: 0.02em;
  opacity: 0.85;
}

.site-footer .footer-col-wrapper{
  margin-top: 0.50rem;
}

.site-footer .contact-list{
  margin-bottom: 0.65rem;
  opacity: 0.9;
}

.site-footer ul{
  list-style: none;
  margin: 0;
  padding: 0;
}

.site-footer li{
  margin: 0.25rem 0;
}

.site-footer a{
  text-decoration: none;
  border-bottom: 1px solid rgba(0, 0, 0, 0.25);
}

.site-footer a:hover,
.site-footer a:focus{
  border-bottom-color: rgba(0, 0, 0, 0.6);
}

/* Quick links row */
.site-footer .footer-links{
  margin-top: 0.65rem;
  display: flex;
  flex-wrap: wrap;
  gap: 0.35rem 0.9rem;
}

.site-footer .footer-links li{
  margin: 0;
}

/* Bottom bar */
.site-footer .footer-bottom{
  margin-top: 0.9rem !important;
  padding-top: 0.6rem !important;
  border-top: 1px solid rgba(0, 0, 0, 0.10);
  text-align: center;
}

.site-footer .footer-bottom p{
  margin: 0.20rem 0;
}

.site-footer .footer-bottom__copyright{
  font-size: 0.95rem;
  opacity: 0.9;
}

.site-footer .footer-bottom__powered{
  font-size: 0.85rem;
  opacity: 0.75;
}

.site-footer .footer-bottom__legal{
  margin-top: 0.45rem;
  font-size: 0.85rem;
  opacity: 0.8;
}

.site-footer .footer-bottom__sep{
  padding: 0 0.5rem;
  opacity: 0.6;
}
