(() => {
  const normalize = (value) =>
    value
      .normalize("NFKD")
      .toLocaleLowerCase()
      .replace(/[^\p{L}\p{N}]+/gu, " ")
      .trim();

  document.querySelectorAll("[data-paper-browser]").forEach((browser) => {
    const form = browser.querySelector("[data-paper-search]");
    const input = browser.querySelector("[data-paper-search-input]");
    const clearButton = browser.querySelector("[data-paper-search-clear]");
    const status = browser.querySelector("[data-paper-search-status]");
    const noResults = browser.querySelector("[data-paper-no-results]");
    const items = Array.from(browser.querySelectorAll("[data-paper-item]"));
    const sections = Array.from(browser.querySelectorAll("[data-paper-section]"));
    const topicGroups = Array.from(browser.querySelectorAll("[data-topic-group]"));
    const pluralLabel = browser.dataset.itemLabelPlural || "papers";

    browser.addEventListener("click", (event) => {
      const toggle = event.target.closest("[data-paper-toggle]");
      if (!toggle || !browser.contains(toggle)) return;

      const panel = document.getElementById(toggle.getAttribute("aria-controls"));
      if (!panel) return;

      const willExpand = toggle.getAttribute("aria-expanded") !== "true";
      toggle.setAttribute("aria-expanded", String(willExpand));
      panel.hidden = !willExpand;
      const item = toggle.closest("[data-paper-item]");
      if (item) item.classList.toggle("is-expanded", willExpand);
    });

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
        if (count) count.textContent = `${visibleInSection} ${visibleInSection === 1 ? "paper" : "papers"}`;
      });

      topicGroups.forEach((group) => {
        group.hidden = query !== "";
      });

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
