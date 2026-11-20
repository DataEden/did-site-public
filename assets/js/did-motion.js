/* ==========================================================================
   Data Inside Data™ LLC
   File: did-motion.js
   Introduced: November 2026

   Purpose:
   Provides safe, opt-in scroll reveal effects using IntersectionObserver.

   Elements fade into view whenever they enter the viewport and reset after
   leaving it, allowing the reveal effect to work while scrolling both down
   and back up the page.

   Content remains visible if JavaScript, IntersectionObserver, or motion
   support is unavailable.

   Part of:
   Data Inside Data™ v3 UI System
   ========================================================================== */

document.addEventListener("DOMContentLoaded", () => {

    const revealElements =
        document.querySelectorAll("[data-reveal]");


    if (!revealElements.length) {
        return;
    }


    const prefersReducedMotion =
        window.matchMedia(
            "(prefers-reduced-motion: reduce)"
        ).matches;


    /*
     * Leave content fully visible when the visitor prefers reduced motion
     * or when IntersectionObserver is unavailable.
     */
    if (
        prefersReducedMotion ||
        !("IntersectionObserver" in window)
    ) {
        return;
    }


    /* ======================================================================
       Repeating reveal observer

       Unlike the original one-time reveal implementation, elements remain
       observed after entering the viewport.

       Enter viewport  → add is-visible
       Leave viewport  → remove is-visible
       Re-enter         → reveal again
       ====================================================================== */

    const observer =
        new IntersectionObserver(
            (entries) => {

                entries.forEach((entry) => {

                    entry.target.classList.toggle(
                        "is-visible",
                        entry.isIntersecting
                    );

                });

            },
            {
                threshold: 0.12,

                /*
                 * Trigger slightly before the element reaches the very
                 * bottom edge of the viewport.
                 */
                rootMargin: "0px 0px -40px 0px"
            }
        );


    revealElements.forEach((element) => {

        /*
         * Enable the animated state only after JavaScript and
         * IntersectionObserver are confirmed available.
         */
        element.classList.add(
            "did-reveal-pending"
        );


        /*
         * Elements already visible when the page first loads should remain
         * visible instead of briefly flashing transparent.
         */
        const rect =
            element.getBoundingClientRect();


        const isInitiallyVisible =
            rect.top < window.innerHeight &&
            rect.bottom > 0;


        if (isInitiallyVisible) {
            element.classList.add(
                "is-visible"
            );
        }


        /*
         * Keep every reveal element under observation so the effect can
         * repeat while scrolling in either direction.
         */
        observer.observe(element);

    });

});