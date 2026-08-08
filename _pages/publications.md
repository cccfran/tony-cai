---
layout: tony
permalink: /papers/
title: Papers
kicker: Research
nav: true
nav_order: 2
---

<nav class="tc-paper-view-tabs" aria-label="Paper views">
  <a href="{{ '/papers/' | relative_url }}" aria-current="page">Chronological</a>
  <a href="{{ '/papers-by-topic/' | relative_url }}">By topic</a>
</nav>

<div class="tc-research-topics" role="list" aria-label="Research areas">
  <div class="tc-research-topic" role="listitem"><strong>Statistical machine learning</strong><span>Transfer, private, and federated learning; statistical and computational tradeoffs</span></div>
  <div class="tc-research-topic" role="listitem"><strong>High-dimensional statistics</strong><span>Low-rank matrices, covariance structures, sparse models, classification, and networks</span></div>
  <div class="tc-research-topic" role="listitem"><strong>Large-scale multiple testing</strong><span>False discovery rate control, structured testing, and simultaneous inference</span></div>
  <div class="tc-research-topic" role="listitem"><strong>Functional data analysis</strong><span>Functional regression, mean and covariance estimation, and phase transitions</span></div>
  <div class="tc-research-topic" role="listitem"><strong>Nonparametric inference</strong><span>Wavelet methods, adaptive estimation, uncertainty quantification, and functionals</span></div>
  <div class="tc-research-topic" role="listitem"><strong>Scientific applications</strong><span>Genomics, chemical identification, medical imaging, and financial econometrics</span></div>
</div>

<div class="tc-paper-browser" data-paper-browser data-item-label-plural="entries">
  <div class="tc-paper-layout">
    <aside class="tc-paper-side" aria-label="Paper navigation">
      <div class="tc-paper-side-inner" data-paper-side-scroll>
        <p class="tc-paper-side-title" id="paper-year-navigation">Browse by year</p>
        <a class="tc-paper-nav-skip" href="#paper-content">Skip navigation</a>
        <nav class="tc-paper-side-nav" aria-labelledby="paper-year-navigation" data-paper-side-nav>
          <ol class="tc-paper-year-list">
            {% for section in site.data.papers.sections %}
              <li><a href="#{{ section.id }}">{{ section.title }}</a></li>
            {% endfor %}
          </ol>
        </nav>
      </div>
    </aside>

    <div class="tc-paper-content" id="paper-content" tabindex="-1">
      <form class="tc-paper-search" role="search" data-paper-search>
        <label for="paper-search-chronological">Search papers</label>
        <div class="tc-paper-search-row">
          <input
            id="paper-search-chronological"
            type="search"
            placeholder="Search by title, author, journal, or year"
            autocomplete="off"
            data-paper-search-input
          >
          <button type="button" data-paper-search-clear>Clear</button>
        </div>
        <p class="tc-paper-search-help">Results update as you type.</p>
        <p class="tc-paper-search-status" role="status" aria-live="polite" data-paper-search-status></p>
      </form>

      <p class="tc-paper-no-results" data-paper-no-results hidden>No papers match that search.</p>

{% for section in site.data.papers.sections %}

<section class="tc-paper-section" id="{{ section.id }}" aria-labelledby="{{ section.id }}-heading" data-paper-section>
<div class="tc-paper-section-heading">
<h2 id="{{ section.id }}-heading">{{ section.title }}</h2>
<span class="tc-count" data-paper-section-count>{{ section.papers.size }} papers</span>
</div>
<ol class="tc-paper-list">
{% for paper in section.papers %}
{% capture paper_instance_id %}paper-{{ section.id }}-{{ paper.id }}{% endcapture %}
{% include paper-item.liquid paper=paper instance_id=paper_instance_id %}
{% endfor %}
</ol>
</section>
{% endfor %}

    </div>

  </div>
</div>

<script defer src="{{ '/assets/js/paper-search.js' | relative_url }}"></script>
