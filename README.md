= Jekyll - Octopod

Podcasting publishing extension for Jekyll

== Installation

  $ gem install jekyll
  $ jekyll new name-of-my-podcast
  $ cd name-of-my-podcast

Create file Gemfile with the contents:

  source 'http://rubygems.org'
  gem 'jekyll-octopod'

Install the dependencies and run the setup script via:

  $ bundle install
  $ octopod setup

Update the configuration settings in the configation file `_config.yaml` in the
application directory.

== Usage

FIXME! Configuration File.
FIXME! You might want to change the images and logos in ...
FIXME! You might want to delete the demo episode files

== Contributions

are welcomed!

== Maintainer

Stefan Haslinger <mailto:stefan.haslinger@informatom.com>


== Credits

This Gem is sitting on the shoulder of giants, lots of the code was not written
by me and/or depends on other code.

Especially to be mentioned: Arne Eilermann eilermann@lavabit.com who started and
created Octopod https://github.com/pattex/octopod

== License

[Licensend under the MIT-License](license.md)

The following assets from seperate projects are packaged in this repo:
* Podlove Webplayer, version 3.0.0-beta.3, http://podlove.org/podlove-web-player/, BSD 2-Clause License
* Bootflat, version 2.0.4, http://bootflat.github.io/, MIT License
* Bootstrap, version 3.3.0 http://getbootstrap.com/, MIT License
* Glyphicons, http://glyphicons.com/, are licensed via Bootstrap
* Font Awesome, version 4.5.0, http://fontawesome.io/, Font: SIL OFL 1.1, CSS: MIT License
* iCheck, version 1.0.1, http://git.io/arlzeA, MIT License
* JQuery, version 1.11.3., https://jquery.com/, MIT License
* Demo Audio from Bensound, http://www.bensound.com/royalty-free-music, CC BY-ND 3.0 License
