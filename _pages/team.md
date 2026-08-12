---
layout: tony
permalink: /team/
title: My Team
kicker: Research group
header_image: /assets/img/page-headers/team_members.png
header_image_credit: "Credit: ChatGPT"
nav: true
nav_order: 4
---

<div class="tc-callout">
  <p>{{ site.data.team.focus }}</p>
</div>

<h2>Current members</h2>
<p><strong>{{ site.data.team.current.role }}</strong></p>
<div class="tc-current-team">
  {% for member in site.data.team.current.members %}
    <span class="tc-person-chip">{{ member }}</span>
  {% endfor %}
</div>

<h2>Past members</h2>
<div class="tc-table-wrap">
  <table class="tc-table">
    <thead>
      <tr>
        <th scope="col">Name</th>
        <th scope="col">Role</th>
        <th scope="col">Placement</th>
      </tr>
    </thead>
    <tbody>
      {% for alumnus in site.data.team.alumni %}
        <tr>
          <td><strong>{{ alumnus.name }}</strong></td>
          <td>{{ alumnus.role }}</td>
          <td>{{ alumnus.position }}</td>
        </tr>
      {% endfor %}
    </tbody>
  </table>
</div>

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
