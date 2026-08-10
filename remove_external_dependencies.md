## How to remove all external dependencies

I wanted to remove all external dependencies and be fully self sustained, so I did the following:

### Turn Twitter widgets into styled buttons

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

Finally,  rebuild, test the site locally and deploy your site as usual.