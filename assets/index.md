---
title: Episodes
layout: default
navigation: 0
---
{% assign post = site.posts.first %}
{% include post.html %}

{% assign current_post = site.posts.first %}
{% for post in site.posts -%}
  {% unless post.url == current_post.url -%}
    {% include post_line.html %}
  {% endunless %}
{% endfor %}
