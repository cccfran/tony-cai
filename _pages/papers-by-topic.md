---
layout: tony
permalink: /papers-by-topic/
title: Papers by Topic
kicker: Research index
nav: false
---

<nav class="tc-paper-view-tabs" aria-label="Paper views">
  <a href="{{ '/papers/' | relative_url }}">Chronological</a>
  <a href="{{ '/papers-by-topic/' | relative_url }}" aria-current="page">By topic</a>
</nav>

<div class="tc-paper-browser" data-paper-browser data-item-label-plural="topic listings">
  <form class="tc-paper-search" role="search" data-paper-search>
    <label for="paper-search-topic">Search papers by topic</label>
    <div class="tc-paper-search-row">
      <input
        id="paper-search-topic"
        type="search"
        placeholder="Search by title, author, topic, journal, or year"
        autocomplete="off"
        data-paper-search-input
      >
      <button type="button" data-paper-search-clear>Clear</button>
    </div>
    <p class="tc-paper-search-help">Cross-listed papers can appear in more than one result section.</p>
    <p class="tc-paper-search-status" role="status" aria-live="polite" data-paper-search-status></p>
  </form>

  <nav class="tc-topic-index" aria-label="Jump to research topic">
    <div class="tc-paper-toolbar">
      {% for topic in site.data.paper_topics.topics %}
        <a href="#{{ topic.id }}"{% if topic.level == 2 %} class="tc-topic-link-sub"{% endif %}>{{ topic.title }}</a>
      {% endfor %}
    </div>
  </nav>

  <p class="tc-paper-no-results" data-paper-no-results hidden>No papers match that search.</p>

{% for topic in site.data.paper_topics.topics %}
{% if topic.count == 0 %}

<section class="tc-paper-section tc-topic-group" id="{{ topic.id }}" aria-labelledby="{{ topic.id }}-heading" data-topic-group>
<div class="tc-paper-section-heading">
<h2 id="{{ topic.id }}-heading">{{ topic.title }}</h2>
<span class="tc-count">Research area</span>
</div>
</section>
{% else %}
<section
        class="tc-paper-section{% if topic.level == 2 %} tc-paper-subtopic{% endif %}"
        id="{{ topic.id }}"
        aria-labelledby="{{ topic.id }}-heading"
        data-paper-section
      >
<div class="tc-paper-section-heading">
<h2 id="{{ topic.id }}-heading">{{ topic.title }}</h2>
<span class="tc-count" data-paper-section-count>{{ topic.count }} papers</span>
</div>
<ol class="tc-paper-list">
{% for source_section in site.data.papers.sections %}
{% for paper in source_section.papers %}
{% if paper.topics contains topic.id %}
{% capture paper_instance_id %}paper-{{ topic.id }}-{{ paper.id }}{% endcapture %}
{% include paper-item.liquid paper=paper instance_id=paper_instance_id topics=topic.title %}
{% endif %}
{% endfor %}
{% endfor %}
</ol>
</section>
{% endif %}
{% endfor %}

</div>

<script defer src="{{ '/assets/js/paper-search.js' | relative_url }}"></script>
