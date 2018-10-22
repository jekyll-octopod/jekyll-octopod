# ROADMAP

This is the first time I (Stefan) writes down some thoughts on the future of jekyll-octopod,
so let's see, how this turns out. Maybe RFC would be a better title for this, so please send
comments to mailto:stefan@panoptikum.io and include a statement, if they may be included here,
so that other people could read them as well.

## Current issues

There are several issues, that I see with jekyll-octopod that could be fixed:

1. The installation script:
   Updating is almost impossible currently because of the installation process, that copies file into
   the project. We could, now that gem based themes a working nicely, extract all the assets into
   a theme, that is then not really a theme any more, but also the store for the webplayer, subscribe
   button and other assets.

2. CSS Framework:
   Bootflat is highly depending on Bootstrap, but not maintained any more, while the 3.x
   Bootstrap version, that we are using, is creating deprecation warnings in some browser's
   development console (I don't remember which one).
   Bootstrap 3 (and 4) comes with a lot of javascript and other bloat, they we are not making any
   use of. Newcomers are overwhelmed by the amount of sass variables in Bootstrap.
   I have created playing around with a new smaller CSS (only - well, almost only to be true)
   framework called [Bulma](https://bulma.io) and already created a jekyll theme for this
   [jekyll-bulma](https://github.com/jekyll-octopod/jekyll-bulma), that I use on my
   [homepage](https://informatom.com) already. This new theme can be used as a basis for the Asset
   gem mentioned in 1.

3. Web Player:
   We having been using Podigee Web Player now for a while, and it works nicely. (Props to the nice
   guys from Podigee, whom I highly appreciate.) Nevertheless, meanwhile I would prefer the
   [Podlove Web Player](https://podlove.org/podlove-web-player/), that could remember the position
   where you left it, but it would introduce a cookie for that - which we didn't use up to now,
   so you should add an extra comment in your data privacy statement then to explain that cookie.
   The cookie wouldn't be evaluated at the server, nevertheless.

4. Ruby dependency:
   I don't really see a way around this, though I see people struggling with getting Ruby working
   on Windows. I have considered a rewrite with a differernt technology - maybe as an Electron
   app using a Node based static site generator or even as a hosted service for non technical
   users providing them with just web forms to fill out. But that would mean giving up on
   Jekyll Octopod all together.

5. Fatigue:
   I feel a bit of fatigue, maintaining Jekyll Octopod now for 28 months. So if anybody of you
   want's to take over as a maintainer, now would be a good point in time. :-)
