(() => {
  const normalize = (value) =>
    value
      .normalize("NFKD")
      .toLocaleLowerCase()
      .replace(/[^\p{L}\p{N}]+/gu, " ")
      .trim();

  const setupSideNavigation = (browser) => {
    const nav = browser.querySelector("[data-paper-side-nav]");
    const scroller = browser.querySelector("[data-paper-side-scroll]");
    if (!nav) return { sync: () => {} };

    const pairs = Array.from(nav.querySelectorAll('a[href^="#"]'))
      .map((link) => {
        const targetId = decodeURIComponent(link.hash.slice(1));
        const target = document.getElementById(targetId);
        const heading = document.getElementById(`${targetId}-heading`) || target;
        return target && heading ? { link, target, heading } : null;
      })
      .filter(Boolean);

    let currentLink = null;
    let updateScheduled = false;

    const isRendered = ({ target }) => !target.hidden && target.getClientRects().length > 0;

    const viewportOffset = () => {
      const navbar = document.getElementById("navbar");
      let offset = (navbar ? navbar.getBoundingClientRect().height : 64) + 18;
      if (window.matchMedia("(max-width: 900px)").matches && scroller) {
        offset += scroller.getBoundingClientRect().height + 10;
      }
      return offset;
    };

    const revealInScroller = (link) => {
      if (!scroller) return;

      const linkRect = link.getBoundingClientRect();
      const scrollerRect = scroller.getBoundingClientRect();

      if (window.matchMedia("(max-width: 900px)").matches) {
        const title = scroller.querySelector(".tc-paper-side-title");
        const leftEdge = scrollerRect.left + (title ? title.getBoundingClientRect().width : 0) + 8;
        if (linkRect.left < leftEdge) scroller.scrollLeft -= leftEdge - linkRect.left;
        if (linkRect.right > scrollerRect.right - 8) scroller.scrollLeft += linkRect.right - scrollerRect.right + 8;
        return;
      }

      if (linkRect.top < scrollerRect.top + 8) scroller.scrollTop -= scrollerRect.top - linkRect.top + 8;
      if (linkRect.bottom > scrollerRect.bottom - 8) scroller.scrollTop += linkRect.bottom - scrollerRect.bottom + 8;
    };

    const setCurrent = (pair) => {
      if ((pair ? pair.link : null) === currentLink) return;

      pairs.forEach(({ link }) => link.removeAttribute("aria-current"));
      nav.querySelectorAll(".is-active-ancestor").forEach((item) => item.classList.remove("is-active-ancestor"));
      currentLink = pair ? pair.link : null;
      if (!pair) return;

      pair.link.setAttribute("aria-current", "location");
      const nestedList = pair.link.closest(".tc-topic-tree ul");
      const parentItem = nestedList ? nestedList.parentElement : null;
      if (parentItem && parentItem.matches("li")) parentItem.classList.add("is-active-ancestor");
      revealInScroller(pair.link);
    };

    const updateCurrent = () => {
      updateScheduled = false;
      const visiblePairs = pairs.filter(isRendered);
      if (visiblePairs.length === 0) {
        setCurrent(null);
        return;
      }

      const offset = viewportOffset();
      let current = visiblePairs[0];
      visiblePairs.forEach((pair) => {
        const scrollMargin = Number.parseFloat(window.getComputedStyle(pair.target).scrollMarginTop) || 0;
        const activationLine = Math.max(offset, scrollMargin) + 1;
        if (pair.heading.getBoundingClientRect().top <= activationLine) current = pair;
      });
      setCurrent(current);
    };

    const scheduleUpdate = () => {
      if (updateScheduled) return;
      updateScheduled = true;
      window.requestAnimationFrame(updateCurrent);
    };

    pairs.forEach((pair) => {
      pair.link.addEventListener("click", () => setCurrent(pair));
    });

    window.addEventListener("scroll", scheduleUpdate, { passive: true });
    window.addEventListener("resize", scheduleUpdate);
    window.addEventListener("hashchange", scheduleUpdate);
    window.addEventListener("paper-layout-change", scheduleUpdate);

    const hashPair = pairs.find(({ link }) => link.hash === window.location.hash);
    if (hashPair) setCurrent(hashPair);
    scheduleUpdate();

    return {
      sync(filtering = false) {
        pairs.forEach((pair) => {
          const item = pair.link.closest("li");
          if (item) item.hidden = filtering && !isRendered(pair);
        });
        scheduleUpdate();
      },
    };
  };

  document.addEventListener("click", (event) => {
    const toggle = event.target.closest("[data-paper-toggle]");
    if (!toggle) return;

    const panel = document.getElementById(toggle.getAttribute("aria-controls"));
    if (!panel) return;

    const willExpand = toggle.getAttribute("aria-expanded") !== "true";
    toggle.setAttribute("aria-expanded", String(willExpand));
    panel.hidden = !willExpand;

    const item = toggle.closest("[data-paper-item], [data-disclosure-item]");
    if (item) item.classList.toggle("is-expanded", willExpand);
    window.dispatchEvent(new Event("paper-layout-change"));
  });

  document.querySelectorAll("[data-paper-browser]").forEach((browser) => {
    const form = browser.querySelector("[data-paper-search]");
    const input = browser.querySelector("[data-paper-search-input]");
    const clearButton = browser.querySelector("[data-paper-search-clear]");
    const status = browser.querySelector("[data-paper-search-status]");
    const noResults = browser.querySelector("[data-paper-no-results]");
    const items = Array.from(browser.querySelectorAll("[data-paper-item]"));
    const sections = Array.from(browser.querySelectorAll("[data-paper-section]"));
    const topicFamilies = Array.from(browser.querySelectorAll("[data-topic-family]"));
    const pluralLabel = browser.dataset.itemLabelPlural || "papers";
    const sideNavigation = setupSideNavigation(browser);

    if (!form || !input || !clearButton || !status || !noResults || items.length === 0) return;

    items.forEach((item) => {
      const searchText = Array.from(item.querySelectorAll("[data-paper-search-field]"))
        .map((field) => field.textContent)
        .join(" ");
      item.dataset.paperSearchText = normalize(`${item.dataset.paperTopics || ""} ${searchText}`);
    });

    const update = () => {
      const query = normalize(input.value);
      let visibleTotal = 0;

      items.forEach((item) => {
        const matches = query === "" || item.dataset.paperSearchText.includes(query);
        item.hidden = !matches;
        if (matches) visibleTotal += 1;
      });

      sections.forEach((section) => {
        const sectionItems = Array.from(section.querySelectorAll("[data-paper-item]"));
        const visibleInSection = sectionItems.filter((item) => !item.hidden).length;
        const count = section.querySelector("[data-paper-section-count]");

        section.hidden = visibleInSection === 0;
        if (count) {
          const qualifier = count.dataset.paperCountQualifier ? `${count.dataset.paperCountQualifier} ` : "";
          count.textContent = `${visibleInSection} ${qualifier}${visibleInSection === 1 ? "paper" : "papers"}`;
        }
      });

      topicFamilies.forEach((family) => {
        const familySections = Array.from(family.querySelectorAll("[data-paper-section]"));
        const visibleInFamily = Array.from(family.querySelectorAll("[data-paper-item]")).filter((item) => !item.hidden).length;
        const count = family.querySelector("[data-topic-total-count]");

        if (count) count.textContent = `${visibleInFamily} ${visibleInFamily === 1 ? "paper" : "papers"}`;
        family.hidden = familySections.every((section) => section.hidden);
      });

      sideNavigation.sync(query !== "");

      clearButton.disabled = query === "";
      noResults.hidden = visibleTotal !== 0;
      status.textContent = query ? `Showing ${visibleTotal} of ${items.length} ${pluralLabel}.` : `${items.length} ${pluralLabel}.`;
    };

    form.addEventListener("submit", (event) => event.preventDefault());
    input.addEventListener("input", update);
    clearButton.addEventListener("click", () => {
      input.value = "";
      update();
      input.focus();
    });

    update();
  });
})();
