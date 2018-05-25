## Howto remove all external dependencies

I wanted to remove all external dependencies and be fully self sustained, so I did the following:

### 1. Remove Disqus commenting by removing from _config.yml
```
## Disqus comments #############################################################
disqus_shortname: # Disqus will not be used unless this is set
disqus_developer: 0 # 1 / 0
```

### 2. Clone the repo into a new directory

### 3. copy /assets/subscribe-button into the main folder
### 4. copy /assets/podcast-player into the main folder

### 5. in _includes/sidebar.html replace
```
<script class="podlove-subscribe-button"
        src="https://cdn.podlove.org/subscribe-button/javascripts/app.js"
        data-language="de"
        data-size="medium"
        data-json-data="podcastData"
        data-colors="#FC6E51;green;blue"
        data-buttonid="123abc"
        data-hide="false">
</script>
```
with
```
<script class="podlove-subscribe-button"
        src="/subscribe-button/javascripts/app.js"
        data-language="{{ site.language }}"
        data-size="medium auto"
        data-style="filled"
        data-json-data="podcastData"
        data-colors="#FC6E51;green;blue">
</script>
```

### 6. in _includes/sidebar.html replace
```
<a href="https://twitter.com/{{ site.twitter_nick }}" class="twitter-follow-button" data-show-count="false">Follow @{{ site.twitter_nick }}</a>
```
with
```
<a href="https://twitter.com/{{ site.twitter_nick }}"
   class="button btn-primary btn-sm"
   data-show-count="false">
  <i class="fa fa-twitter"></i>Follow @{{ site.twitter_nick }}
</a>
```

### 7. in _includes/post.html replace
```
<a href="https://twitter.com/share" class="twitter-share-button" data-url="{{ site.url }}{{post.url }}" data-text="{{ post.title }}">Tweet</a>
```
with
```
<a href="https://twitter.com/share"
   class="button btn-primary btn-sm"
   data-url="{{ site.url }}{{post.url }}"
   data-text="{{ post.title }}">
  <i class="fa fa-twitter"></i> Tweet</a>
```

### 8. in _layouts/default.html (and _layouts/with_twitter_card.html, if it exists) delete
```
<script>
!function(d,s,id){var js,fjs=d.getElementsByTagName(s)[0];if(!d.getElementById(id)){js=d.createElement(s);js.id=id;js.src="//platform.twitter.com/widgets.js";fjs.parentNode.insertBefore(js,fjs);}}(document,"script","twitter-wjs");
</script>
```

### 9. in _layouts/default.html (and _layouts/with_twitter_card.html, if it exists) delete
```
<script src='https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML'></script>
```

### 10. Removed Flattr buttons by deleting in _config.yml
```
flattr_uid: # Flattr will not be used unless this is set
flattr_button: compact # compact | default
flattr_mode: auto # auto | manual(default)
flattr_popout:  1 # 1 | 0 (show popout when hovering mouse over button)
flattr_language: en_GB # available languages - https://api.flattr.com/rest/v2/languages.txt
flattr_category: audio # available categories - https://api.flattr.com/rest/v2/categories.txt
```

Finally rebuild and deploy your site.

Yes, I anbandomed comments and Flattr integration that way, but the declease in load time of my
page made more than up for that. And neither of these features were used, anyways ;-(, my listeners
tend to prefer to comment via email.