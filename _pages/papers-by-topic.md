---
layout: tony
permalink: /papers-by-topic/
title: Papers by Topic
kicker: Research index
header_image: /assets/img/page-headers/papers.png
header_image_credit: "Credit: ChatGPT"
nav: false
---

{% assign paper_topics = site.data.paper_topics.topics %}
{% assign topic_families = paper_topics | where: "level", 1 %}

<nav class="tc-paper-view-tabs" aria-label="Paper views">
  <a href="{{ '/papers/' | relative_url }}">Chronological</a>
  <a href="{{ '/papers-by-topic/' | relative_url }}" aria-current="page">By topic</a>
</nav>

<div class="tc-paper-browser" data-paper-browser data-item-label-plural="topic listings">
  <div class="tc-paper-layout">
    <aside class="tc-paper-side" aria-label="Paper navigation">
      <div class="tc-paper-side-inner" data-paper-side-scroll>
        <p class="tc-paper-side-title" id="paper-topic-navigation">Browse by topic</p>
        <nav class="tc-topic-index tc-paper-side-nav" aria-labelledby="paper-topic-navigation" data-paper-side-nav>
          <ul class="tc-topic-tree">
            {% for topic in topic_families %}
              {% assign child_topics = paper_topics | where: "parent_id", topic.id %}
              <li>
                <a href="#{{ topic.id }}">{{ topic.title }}</a>
                {% if child_topics.size > 0 %}
                  <ul>
                    {% for child in child_topics %}
                      <li><a href="#{{ child.id }}">{{ child.title }}</a></li>
                    {% endfor %}
                  </ul>
                {% endif %}
              </li>
            {% endfor %}
          </ul>
        </nav>
      </div>
    </aside>

    <div class="tc-paper-content" id="paper-content" tabindex="-1">
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

      <p class="tc-paper-no-results" data-paper-no-results hidden>No papers match that search.</p>

{% for topic in topic_families %}
{% assign child_topics = paper_topics | where: "parent_id", topic.id %}
{% assign topic_total_count = topic.count %}
{% for child in child_topics %}
{% assign topic_total_count = topic_total_count | plus: child.count %}
{% endfor %}

<section
      class="tc-topic-family"
      id="{{ topic.id }}"
      aria-labelledby="{{ topic.id }}-heading"
      data-topic-family
    >
<div class="tc-paper-section-heading tc-topic-family-heading">
        <h2 id="{{ topic.id }}-heading">{{ topic.title }}</h2>
        {% if topic_total_count > 0 %}
          <span
            class="tc-count"
            data-topic-total-count
          >
            {{- topic_total_count }} {% if topic_total_count == 1 %}paper{% else %}papers{% endif -%}
          </span>
        {% endif %}
</div>

      {% if topic.count > 0 %}
        <div class="tc-topic-direct-papers" data-paper-section>
          <ol class="tc-paper-list">
            {% for source_section in site.data.papers.sections %}
              {% for paper in source_section.papers %}
                {% if paper.topics contains topic.id %}
                  {% capture paper_instance_id %}paper-{{ topic.id }}-{{ paper.id }}{% endcapture %}
                  {% if source_section.id == 'reports' %}
                    {% assign paper_display_number = forloop.index %}
                  {% else %}
                    {% assign paper_display_number = paper.cv_number | plus: site.data.papers.technical_report_count %}
                  {% endif %}
                  {% include paper-item.liquid paper=paper instance_id=paper_instance_id topics=topic.title number=paper_display_number %}
                {% endif %}
              {% endfor %}
            {% endfor %}
          </ol>
        </div>
      {% endif %}

      {% if child_topics.size > 0 %}
        <div class="tc-topic-subtopics">
          {% for child in child_topics %}
            <section
              class="tc-paper-section tc-paper-subtopic"
              id="{{ child.id }}"
              aria-labelledby="{{ child.id }}-heading"
              data-paper-section
            >
              <div class="tc-paper-section-heading">
                <h3 id="{{ child.id }}-heading">{{ child.title }}</h3>
                <span class="tc-count" data-paper-section-count>
                  {{- child.count }} {% if child.count == 1 %}paper{% else %}papers{% endif -%}
                </span>
              </div>
              <ol class="tc-paper-list">
                {% for source_section in site.data.papers.sections %}
                  {% for paper in source_section.papers %}
                    {% if paper.topics contains child.id %}
                      {% capture paper_instance_id %}paper-{{ child.id }}-{{ paper.id }}{% endcapture %}
                      {% if source_section.id == 'reports' %}
                        {% assign paper_display_number = forloop.index %}
                      {% else %}
                        {% assign paper_display_number = paper.cv_number | plus: site.data.papers.technical_report_count %}
                      {% endif %}
                      {% include paper-item.liquid paper=paper instance_id=paper_instance_id topics=child.title number=paper_display_number %}
                    {% endif %}
                  {% endfor %}
                {% endfor %}
              </ol>
            </section>
          {% endfor %}
        </div>
      {% endif %}
    </section>

{% endfor %}

    </div>

  </div>
</div>

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
