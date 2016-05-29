# Jekyll - Octopod

![logo](assets/img/logo.jpg)

A Podcasting publishing extension for the static site generator [Jekyll](https://jekyllrb.com/).

## tl;dr

You generate a static web site for your podcast on your own computer and sync it to your web space. So no Wordpress, PHP, Ruby, Perl, etc. is needed on your server.

## Tell me more!

If you want to take a look: See (and listen to) Stefan's podcast [Aua-Uff-Code!](https://aua-uff-co.de) or find a screenshot below.

Technically Jekyll-Octopod is a Jekyll plugin and a Ruby Gem. It contains of
scripts, templates, helpers and extensions to deliver your podcasts the cool text file lover's way.

If you are not afraid of the command line of your computer and text files are the stuff to heat up your geeky little heart, Octopod may be worth a trial to publish your podcasts.

The underlying assumptions of Octopod are that static content should be delivered statically and text files are the perfect way to handle podcast metadata. So Octopod makes it easy to generate and deploy a website and feeds for your podcast out of one textfile and at least one audio file per episode.


## Features

Jekyll-Octopod brings innately:
* iTunes ready episode feeds for different file formats (e.g. mp3, ogg, m4a)
* a ready to use [Bootflat](http://bootflat.github.io/) and  [Twitter Bootstrap](http://twitter.github.com/bootstrap/) based, responsible (i.e. mobile friendly) layout modifiable to your heart's desire.
* [Flattr](https://flattr.com/) support on the website and in the episode feed
* [Twitter](https://twitter.com) integration on the website
* comments via [Disqus](http://disqus.com/)
* [Podlove Web Player](http://podlove.org/podlove-web-player/) in it's current version 3.0
* Static player pages that are embeddable in iframes at your other or affiliates' sites
* [Podlove Alternate Feeds](http://podlove.org/alternate-feeds/)
* [Podlove Simple Chapters](http://podlove.org/simple-chapters/)
* [Podlove Subscribe Button](http://podlove.org/podlove-subscribe-button/) for easy podcast subscription on any operating system, including mobile phones.
* https compatibilty
* Google search integration
* easy creation of shownotes

***Is this production ready? *** We use it in production and believe it is.
But it is very likely, that it still contains bugs. Hopefully you are brave enough to play with this cute little toy anyway.

This project is absolutely in a non 1.0 status. This means that there is no guarantee that behavior will change with the next update.

## Prerequesites

The [Ruby programming language](http://www.ruby-lang.org/) and it's package manager [Bundler](http://gembundler.com/).

Nice installation guides for the different operating systems can be found at
the [Rails Girls Website](http://guides.railsgirls.com/install). You can stop
right before installing Rails, because we do not depend on Ruby on Rails here.

You can check, if you succeeded, by entering
```
$ ruby -v
$ gem -v
```
at the command prompt. Both commands should return version greater or equal 2.0 .

## Installation

First, install jekyll, create a new application and cd into it:

```
$ gem install jekyll
$ jekyll new name-of-my-podcast
$ cd name-of-my-podcast
```

Create a file `Gemfile` with the contents:

```
source 'http://rubygems.org'
gem 'jekyll-octopod'
```

This way, we tell Jekyll, that we want to use Jekyll-Octopod.
Now we install the Jekyll-Octopod and it's dependencies and run the setup script via:

```
$ bundle install
$ octopod setup
```

The setup script copies all assets (for example the theme and templates) into your project. If you answer the first question with capital Y, you won't be asked again and all files are copied in batch.

Finally, generate the site and test drive it:

```
$ octopod build
$ octopod serve
```

## Demo

Open a browser tab and navigate to ```http://localhost:4000```.
You should see the fully functional podcasting site like

![demo](materials/demo.png)

Episode 0 is a demo episode. You can even listen to the nice tune
[Jazz Comedy](http://www.bensound.com/royalty-free-music/track/jazz-comedy) from Bensound using the web player.

## Usage

Next, update the configuration settings in the configation file `_config.yaml` in the application directory. (You are already in it.)

* You might want to change the images and logos in the `img` directory
* You might want to change the demo episode file and the Jekyll Welcome post in `_posts` and `_episodes`

You can find a documentation of all the non Octopod specific settings on the [Configuration page of the Jekyll Wiki](https://github.com/mojombo/jekyll/wiki/Configuration).

Jekyll is highly customizable, if you are into coding (or even just want to get into it), read the [Jekyll Documentation](https://jekyllrb.com/docs/home/). It is very detailed and quite easy to grasp.

First of all, your new podcast episode needs audio data. Octopod assumes that
your ready to use audio files stay within the `episodes` directory in in
your projects root.

    cp ~/my_superduper_audio_files/ocp001.m4a episodes

In addition, Octopod assumes that the different audio files of each of your
episode are the same content in various formats which are the same duration
and everything.  
If they are not, you may confuse your listeners. At the least when you are
using the chapters feature.

Next up your episode needs some metadata. A title, some kind of a description,
maybe chapters and so on. Octopod keeps all these metadata in one single
textfile (Protip: these dear little tots feel very lucky when they might
live in a version control system!).  
Octopod kindly helps you generating these file with the `octopod episode`
command (You will find some more inforamtion on the `octopod` command line
tool in

FIXME! command line docu similar to:
[the Octopod wiki](https://github.com/pattex/octopod/wiki/The-octopod-command-line-tool)).

The following command

    octopod episode --title "Why I <3 Octopod"

will generate you a template called **YYYY-MM-DD-why-i-_3-octopod.md** (YYYY-MM-DD represents the current date) in your `_posts` subdirectory. When you open it in your text editor you'll see something like that:

    ---
    title: Why I <3 Octopod
    layout: post
    author: Uncle Octopod
    explicit: 'no'
    audio:
      m4a: name.m4a
      mp3: name.mp3
      opus: name.opus
    ---
    Insert eloquent and worth reading text here.

    {{ page | web_player:site }}

    ## Shownotes
    * Note

The part between the "---" and the "---" is [the YAML front matter](https://github.com/pattex/octopod/wiki/The-post-template). This is where all the metadata is stored. Below the YAML frontmatter is the area (body) where you can write down your posts content (like the show notes and stuff). This strange looking `{{ page | web_player:site }}` thingy is the [Liquid filter](https://github.com/pattex/octopod/wiki/Liquid-filters) which represents the web player later.

When all this work is done you are ready to take a first look.  
The following command generates your site and start a local webserver for a preview. You kann check your new pocasting website by opening [http://localhost:4000](http://localhost:4000).

    octopod --url "http://localhost:4000" --server

If everything is alright you can finally generate your "real" Site:

    octopod

And deploy it to your server:

    octopod deploy

*Attention*: The Rsync settings in your `_config.yml` are mandatory for this last step. But it is no problem to upload the generated website from the `_site` subdirectory via FTP or something.


## Contributions

[Bug reports](https://github.com/informatom/jekyll-octopod/issues) and even more push requests are highly welcome!

At the moment Jekyll-Octopod is extremely made to fit my personal needs and preferences. But it's it is a high priority goal to become Jekyll-Octopod more generic. This and of course bug fixes would make the sweet little octopod mascot smile the most.

But feel free to fork and push request and code and everything.

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Maintainer

Stefan Haslinger <mailto:stefan.haslinger@informatom.com>


## Credits

This Gem is sitting on the shoulder of giants, most of the code was not written
by me and/or depends on other code.

Especially to be mentioned:
* Arne Eilermann eilermann@lavabit.com who started and created Octopod https://github.com/pattex/octopod
* [Jekyll](http://jekyllrb.com/)
* [Twitter Bootstrap](http://twitter.github.com/bootstrap/)
* [The whole Podlove project](http://podlove.org/)
* [Octopress](http://octopress.org/)

The beautiful Octopod Logo was designed and created by [Thekla "TeMeL" Löhr](http://www.temel-art.de/). Please support her with a little flattr.
<a href="https://flattr.com/thing/526869/TeMeL-on-Flattr" target="_blank"><img src="http://api.flattr.com/button/flattr-badge-large.png" alt="Flattr this" title="Flattr this" border="0" /></a>


## License

[Licensend under the MIT-License](LICENSE)

The following assets from seperate projects are packaged in this repo:
* The cute Octopod Logo is by Thekla "TeMeL" Löhr, http://www.temel-art.de/, CC BY 3.0 Germany License
* Podlove Webplayer, version 3.0.0-beta.3, http://podlove.org/podlove-web-player/, BSD 2-Clause License
* Bootflat, version 2.0.4, http://bootflat.github.io/, MIT License
* Bootstrap, version 3.3.0 http://getbootstrap.com/, MIT License
* Glyphicons, http://glyphicons.com/, are licensed via Bootstrap
* Font Awesome, version 4.5.0, http://fontawesome.io/, Font: SIL OFL 1.1, CSS: MIT License
* iCheck, version 1.0.1, http://git.io/arlzeA, MIT License
* JQuery, version 1.11.3., https://jquery.com/, MIT License
* Demo Audio from Bensound, http://www.bensound.com/royalty-free-music, CC BY-ND 3.0 License
