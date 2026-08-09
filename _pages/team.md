---
layout: tony
permalink: /team/
title: My Team
kicker: Research group
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
        <th scope="col">Current position</th>
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
