---
layout: tony
permalink: /special-lectures/
title: Special Lectures
kicker: Invited lectures
nav: true
nav_order: 3
---

<ol class="tc-lecture-list">
  {% for lecture in site.data.special_lectures.lectures %}
    {% include lecture-card.liquid lecture=lecture %}
  {% endfor %}
</ol>

<script defer src="{{ '/assets/js/paper-search.js' | relative_url }}"></script>
