---
layout: tony
permalink: /special-lectures/
title: Special Lectures
kicker: Special Invited lectures
header_image: /assets/img/page-headers/special_lectures.png
nav: true
nav_order: 3
---

<ol class="tc-lecture-list">
  {% for lecture in site.data.special_lectures.lectures %}
    {% include lecture-card.liquid lecture=lecture %}
  {% endfor %}
</ol>

<script defer src="{{ '/assets/js/paper-search.js' | relative_url }}"></script>

<section class="tc-visitor-counter" aria-label="Website visitor counter">
  <div class="statcounter">
    <script>
      var sc_project = 379152;
      var sc_invisible = 0;
      var sc_security = "";
    </script>
    <script src="https://secure.statcounter.com/counter/counter.js"></script>
    <noscript>
      <a href="https://statcounter.com/" target="_blank" rel="noopener noreferrer">
        <img
          class="statcounter"
          src="https://c.statcounter.com/379152/0//0/"
          alt="Website visitor counter"
          referrerpolicy="no-referrer-when-downgrade"
        >
      </a>
    </noscript>
  </div>
   <span>Visits</span>
</section>
