
/* ==========================================================================
   Data Inside Data™ LLC
   File: did-page-controls.js
   Introduced: November 2026

   Purpose:
   Provides shared Data Inside Data™ v3 client-side interface behavior,
   including:

   - top / bottom page navigation
   - internal DID section navigation
   - light / dark theme control
   - repeating reveal motion

   Accessibility:
   Respects the visitor's reduced-motion preference.

   Part of:
   Data Inside Data™ v3 UI System
   ========================================================================== */

document.addEventListener("DOMContentLoaded", () => {

    /* ======================================================================
       Shared accessibility preference
       ====================================================================== */

    const prefersReducedMotion = window.matchMedia(
        "(prefers-reduced-motion: reduce)"
    ).matches;

    const scrollBehavior =
        prefersReducedMotion ? "auto" : "smooth";


    /* ======================================================================
       1. Global top / bottom page controls
       ====================================================================== */

    const controls =
        document.querySelectorAll("[data-scroll-target]");


    controls.forEach((control) => {

        control.addEventListener("click", () => {

            const target =
                control.dataset.scrollTarget;


            if (target === "top") {

                window.scrollTo({
                    top: 0,
                    behavior: scrollBehavior
                });

                return;
            }


            if (target === "bottom") {

                window.scrollTo({
                    top: document.documentElement.scrollHeight,
                    behavior: scrollBehavior
                });
            }

        });

    });

/* ==========================================================================
   Context-aware page-control visibility

   Keep navigation controls available without unnecessarily covering content.
   ========================================================================== */

const upControl =
    document.querySelector(".did-page-control--up");

const downControl =
    document.querySelector(".did-page-control--down");


const updatePageControlVisibility = () => {

    const scrollTop =
        window.scrollY ||
        document.documentElement.scrollTop;

    const viewportHeight =
        window.innerHeight;

    const documentHeight =
        document.documentElement.scrollHeight;


    const nearTop =
        scrollTop < 180;


    const nearBottom =
        scrollTop + viewportHeight >=
        documentHeight - 100;


    if (upControl) {
        upControl.classList.toggle(
            "is-hidden",
            nearTop
        );
    }


    if (downControl) {
        downControl.classList.toggle(
            "is-hidden",
            nearBottom
        );
    }
};


window.addEventListener(
    "scroll",
    updatePageControlVisibility,
    { passive: true }
);


window.addEventListener(
    "resize",
    updatePageControlVisibility
);


updatePageControlVisibility();

    /* ======================================================================
       2. DID internal-section navigation

       Positions linked sections beneath the sticky DID masthead while
       preserving visual breathing room between the navigation and target.
       ====================================================================== */

    document
        .querySelectorAll("[data-did-scroll]")
        .forEach((link) => {

            link.addEventListener("click", (event) => {

                const targetSelector =
                    link.getAttribute("href");


                if (
                    !targetSelector ||
                    !targetSelector.startsWith("#")
                ) {
                    return;
                }


                const target =
                    document.querySelector(targetSelector);


                if (!target) {
                    return;
                }


                event.preventDefault();


                const masthead =
                    document.querySelector(".masthead");


                const mastheadHeight =
                    masthead
                        ? masthead.getBoundingClientRect().height
                        : 0;


                /*
                 * Approximately 2rem of visual space between the sticky
                 * masthead and the linked section.
                 */
                const sectionGap = 32;


                const targetDocumentTop =
                    target.getBoundingClientRect().top +
                    window.scrollY;


                const targetPosition =
                    targetDocumentTop -
                    mastheadHeight -
                    sectionGap;


                window.scrollTo({
                    top: targetPosition,
                    behavior: scrollBehavior
                });


                /*
                 * Update the URL fragment without triggering another
                 * browser-controlled anchor jump.
                 */
                history.replaceState(
                    null,
                    "",
                    targetSelector
                );

            });

        });

    /* ==========================================================================
    Theme-aware masthead logo

    The document's `data-theme` attribute is the source of truth.
    Whenever that attribute changes, update the masthead logo automatically.
    ========================================================================== */

    const updateThemeLogo = () => {
        const logo = document.querySelector(".site-logo img");
        const assets = window.DID_THEME_ASSETS;

        if (!logo || !assets) {
            return;
        }

        const currentTheme =
            document.documentElement.getAttribute("data-theme") || "light";

        const nextLogo =
            currentTheme === "dark"
                ? assets.logoDark
                : assets.logoLight;

        /*
        * Avoid rewriting the image source unnecessarily.
        */
        if (logo.getAttribute("src") !== nextLogo) {
            logo.setAttribute("src", nextLogo);
        }
    };


    /*
    * Set the correct logo immediately after the DOM becomes available.
    */
    updateThemeLogo();


    /*
    * Watch the root <html> element.
    *
    * The theme controller already changes:
    *
    *     <html data-theme="light">
    *
    * to:
    *
    *     <html data-theme="dark">
    *
    * So the logo can react directly to that state instead of depending on
    * a particular button or theme-toggle implementation.
    */
    const themeLogoObserver = new MutationObserver(() => {
        updateThemeLogo();
    });


    themeLogoObserver.observe(
        document.documentElement,
        {
            attributes: true,
            attributeFilter: ["data-theme"]
        }
    );

    /* ======================================================================
       3. Theme-toggle creation

       Minimal Mistakes continues to own the masthead HTML.

       DID progressively inserts the theme control into the existing
       navigation rather than overriding the masthead include.
       ====================================================================== */

    const createThemeToggle = () => {

        const siteNav =
            document.querySelector("#site-nav");


        if (!siteNav) {
            return null;
        }


        /*
         * Prevent duplicate controls if this script is ever evaluated
         * more than once.
         */
        const existingToggle =
            siteNav.querySelector(
                "[data-theme-toggle]"
            );


        if (existingToggle) {
            return existingToggle;
        }


        const toggle =
            document.createElement("button");


        toggle.className =
            "did-theme-toggle";

        toggle.type =
            "button";


        toggle.setAttribute(
            "data-theme-toggle",
            ""
        );

        toggle.setAttribute(
            "aria-label",
            "Switch theme"
        );

        toggle.setAttribute(
            "title",
            "Switch theme"
        );

        toggle.setAttribute(
            "aria-pressed",
            "false"
        );


        const icon =
            document.createElement("span");


        icon.className =
            "did-theme-toggle__icon";

        icon.setAttribute(
            "aria-hidden",
            "true"
        );

        icon.textContent =
            "☾";


        toggle.appendChild(icon);


        const searchToggle =
            siteNav.querySelector(
                ".search__toggle"
            );


        const menuToggle =
            siteNav.querySelector(
                ".greedy-nav__toggle"
            );


        /*
         * Preferred masthead order:
         *
         * navigation → search → theme → mobile menu
         */
        if (searchToggle) {

            searchToggle.insertAdjacentElement(
                "afterend",
                toggle
            );

        } else if (menuToggle) {

            siteNav.insertBefore(
                toggle,
                menuToggle
            );

        } else {

            siteNav.appendChild(toggle);
        }


        return toggle;
    };


    /* ======================================================================
       4. Theme controller

       The early script in `_includes/head/custom.html` determines the theme
       before first paint.

       This controller handles manual visitor changes after the page loads.
       ====================================================================== */

    const themeToggle =
        createThemeToggle();


    if (themeToggle) {

        const storageKey =
            "did-theme";


        const getCurrentTheme = () =>
            document.documentElement
                .getAttribute("data-theme") ||
            "light";


        const updateThemeToggle = () => {

            const currentTheme =
                getCurrentTheme();


            const nextTheme =
                currentTheme === "dark"
                    ? "light"
                    : "dark";


            themeToggle.setAttribute(
                "aria-label",
                `Switch to ${nextTheme} theme`
            );


            themeToggle.setAttribute(
                "title",
                `Switch to ${nextTheme} theme`
            );


            themeToggle.setAttribute(
                "aria-pressed",
                currentTheme === "dark"
                    ? "true"
                    : "false"
            );


            const icon =
                themeToggle.querySelector(
                    ".did-theme-toggle__icon"
                );


            if (icon) {

                icon.textContent =
                    currentTheme === "dark"
                        ? "☀"
                        : "☾";
            }
        };


        themeToggle.addEventListener(
            "click",
            () => {

                const currentTheme =
                    getCurrentTheme();


                const newTheme =
                    currentTheme === "dark"
                        ? "light"
                        : "dark";


                document.documentElement
                    .setAttribute(
                        "data-theme",
                        newTheme
                    );


                /*
                 * Remember an explicit visitor preference.
                 *
                 * If browser storage is unavailable, theme switching still
                 * works for the current page.
                 */
                try {

                    localStorage.setItem(
                        storageKey,
                        newTheme
                    );

                } catch (error) {

                    /* No persistence available. */
                }


                updateThemeToggle();

            }
        );


        updateThemeToggle();
    }
});