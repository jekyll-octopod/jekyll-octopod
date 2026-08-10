## How to remove all external dependencies

I wanted to remove all external dependencies and be fully self sustained, so I did the following:

### 1. Remove Disqus commenting

Remove from _config.yml
```
## Disqus comments #############################################################
disqus_shortname: # Disqus will not be used unless this is set
disqus_developer: 0 # 1 / 0
```

### 2. Self host Subscribe button and Podigee podcast player

* Clone the repo into a new directory

* copy /assets/subscribe-button into the main folder
* copy /assets/podcast-player into the main folder

* in _includes/sidebar.html replace
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

### 3. Turn Twitter widgets into styled buttons

* in _includes/sidebar.html replace
```
<a href="https://twitter.com/{{ site.twitter_nick }}" class="twitter-follow-button" data-show-count="false">Follow @{{ site.twitter_nick }}</a>
```
with
```
<a href="https://twitter.com/{{ site.twitter_nick }}"
   class="button is-primary is-small"
   data-show-count="false">
  <i class="lab la-twitter"></i>Follow @{{ site.twitter_nick }}
</a>
```

* in _includes/post.html replace
```
<a href="https://twitter.com/share" class="twitter-share-button" data-url="{{ site.url }}{{post.url }}" data-text="{{ post.title }}">Tweet</a>
```
with
```
<a href="https://twitter.com/share"
   class="button is-primary is-small"
   data-url="{{ site.url }}{{post.url }}"
   data-text="{{ post.title }}">
  <i class="lab la-twitter"></i> Tweet</a>
```

* in _layouts/default.html (and _layouts/with_twitter_card.html, if it exists) delete
```
<script>
!function(d,s,id){var js,fjs=d.getElementsByTagName(s)[0];if(!d.getElementById(id)){js=d.createElement(s);js.id=id;js.src="//platform.twitter.com/widgets.js";fjs.parentNode.insertBefore(js,fjs);}}(document,"script","twitter-wjs");
</script>
```

* in _layouts/default.html (and _layouts/with_twitter_card.html, if it exists) delete
```
<script src='https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML'></script>
```


Finally,  rebuild, test the site locally and deploy your site as usual.

Yes, I anbandomed comments that way, but the decrease in load time of my
page made more than up for that. That feature wasn't used, anyways ;-(, my listeners
tend to prefer to comment via email.