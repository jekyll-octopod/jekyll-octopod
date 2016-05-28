# Jekyll - Octopod

A Podcasting publishing extension for the static site generator [Jekyll](https://jekyllrb.com/).

## Prerequesites

The programming language Ruby and it's package manager Bundler.

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

```
$ gem install jekyll
$ jekyll new name-of-my-podcast
$ cd name-of-my-podcast
```

Create file Gemfile with the contents:

```
source 'http://rubygems.org'
gem 'jekyll-octopod'
```

Install the dependencies and run the setup script via:

```
$ bundle install
$ octopod setup
```

Update the configuration settings in the configation file `_config.yaml` in the
application directory.

  * You might want to change the images and logos in ...
  * You might want to delete the demo episode files


## Usage


## Contributions

are welcome!

## Maintainer

Stefan Haslinger <mailto:stefan.haslinger@informatom.com>


## Credits

This Gem is sitting on the shoulder of giants, lots of the code was not written
by me and/or depends on other code.

Especially to be mentioned: Arne Eilermann eilermann@lavabit.com who started and
created Octopod https://github.com/pattex/octopod

## License

[Licensend under the MIT-License](license.md)

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
