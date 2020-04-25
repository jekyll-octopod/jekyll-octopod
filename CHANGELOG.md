# Changelog

## 0.9.23 - 2020-04-25

### Fixed

- Broken rss feeds.

## 0.9.22 - 2020-04-23

### Fixed

- Check for wrong language in post_header, so wrong date format was displayed.

## 0.9.21 - 2020-04-18

### Bugfix

- Last published version had wrong version of jekyll-bootflat as a dependency

## 0.9.20 - 2020-04-14

### Fixed

- Google Play Icon and Gpodder Icon. Thanks to Chester Wisniewski!

## 0.9.15, 0.9.16, 0.9.17, 0.9.18, 0.9.19 - 2020-04-08

### Changed

- config_theme not working
- octopod episode created deprecated example file
- updated dependency to latest version of jekyll-bootflat 0.3.2
- fixed issues with font-awesome-sass gem within jekyll-bootflat
- Bumped versions of dependencies, especially Jekyll to 4.0

## 0.9.14 - 2020-03-23

### Fixed

- Dump, when files where hosted externally.
- Filesizes now can be provided via front matter.

## 0.9.12 - 2019-01-18

### Fixed

- Layout 'with_twitter_card' used by episode default view had already several
  differences to the default layout.

## 0.9.11 - 2019-01-09

### Changed

- Increasede Jekyll Version dependency to mitigate vulnerability in certain 
  Jekyll versions.

## 0.9.10 - 2019-01-09

### Fixed

- Ubuntu font was required, but not properly loaded. It is now available in
  /assets/fonts/ubuntu/ via the required version of jekyll-bootflat

## 0.9.9 - 2018-08-13

### Changed

- moved jekyll-octopod into the plugins section of the `_config.yml` file to get rid of the
  deprecation warning

## 0.9.8 - 2018-08-13

### Changed

- cleaned up `_config.yml`: conistent comments, options and descriptions
- added all config options available to `_config.yml`. Commented out the unimportant ones.
- there was an inconsistency on episode level: `episode-cover` and `image` where both expected to be filled
  for an episode cover image. `image` is the one and only param from now on.
  It should contain the image filename and the file should be put in the img directory. (That has
  not changed.)

## 0.9.7 - 2018-08-10

#### Changed

- Roboto fonts for Podlove Subscribe Button now include cyrillic and greek character sets

## 0.9.6 - 2018-07-11

#### Changed
- Dependency Podigee Podcast Player is now included and therefor served locally
- Dependency Podlove Subscribe Button is now included and therefor served locally
- Twitter Buttons are now simply decorated links (and no 'twitter widgets').
- This means no data transfered with requests to external CDNs any more.
- Talks menu item only displayed, if any.

#### Removed
- Removed support for Mathjax

## 0.9.5 - 2018-04-25
#### Added
- Podigee Player theme is now configureable (thanks to https://github.com/marksweiss)

#### Fixed
- Bug in site search (thanks to https://github.com/marksweiss)

## 0.9.4 - 2018-03-20
#### Changed
- Fixed a bug, that demo site could not be created (thanks to https://github.com/marksweiss)
- Chapters are not mandatory any more (thanks to https://github.com/kylemhall)

## 0.9.3 - 2017-12-06
#### Added
- Added a changelog

#### Changed
- Fixed an XML-encoding bug in podcast feeds

#### Removed
- Removed the guid from enclosures in podcast feeds

## 0.9.2 - 2017-10-30
#### Changed
- fixed a weird highlighting issue: In certain posts certain parts suddenly got
  syntax highlighted and displayed as code

## 0.9.1 - 2017-09-12
#### Added
- rudimentary support for twitter cards (you have to register your domain for twitter cards
  yourself, though!)

#### Changed
- fixed the malformed itunes:category tag in the podcast feed
- fixed a bug in the download link

## 0.9.0 - 2017-06-04
#### Added
- Jsonfeeds for all attachment types

## 0.8.9 - 2017-04-07
#### Fixed
- Fixed a bug, that whole post get's included in guid insteat of guid itself

## 0.8.8 - 2017-05-15
#### Added
- Jekyll admin: a gui web interface for adding posts in development locally

## 0.8.7 - 2017-02-09
#### Added
- Swiss theme as an option

## 0.8.6 - 2017-02-08
#### Added
- Support for Jekyll 3.4

## 0.8.5 - 2017-02-08
#### Changed
- Fixed a bug in project dependency paths

## 0.8.4 - 2017-02-08
#### Added
- Localized date formats on the web site
#### Changed
- Uses the version in the feed generator tag of the feeds
- Initial support for Swiss theme

## 0.8.2 - 2017-02-03
#### Added
- support for hosting audio files on an external server<br/>
  use download_url attribute in _config.yml to specify

## 0.8.1 - 2017-02-01
#### Added
- isso integration as an option
#### Changed
- removed Gemfile.lock from the repo
- fixed some typos on the webpage

## 0.8.0 - 2017-01-30
#### Added
- support for contributors on episode level in feeds and on website
- support for images on episode level

## 0.7.9 - 2017-01-30
#### Changed
- feed now uses https links, as Itunes support them as well
- improving legibility and including episode subtitles on website
#### Added
- basic support for isso comment system

## 0.7.8 - 2017-01-17
#### Changed
- fixed a bug on the web player
- fixed a bug in mathjax integration
- fixed typos on the website

## 0.7.7 - 2017-01-14
#### Changed
- updates json-bootflat dependency
- internationalization for podlove subscribe button from the language config attribute
- fixes a bug in file exclusion
- smaller example sound files

## 0.7.5 - 2017-01-05
#### Added
- Mathjax support
#### Changed
- removed an old hack that is no longer necessary (GEM_DIR)
- updating the files excluded

## 0.7.2 - 2016-12-08
#### Changed
- reduces the number of audio formats, that have to exist to one

## 0.7.1 - 2016-12-07
#### Changed
- Using Podigee Player instead of Podlove Webplayer
- Proper gem dependencies instead of including them in the repo

## 0.6.7 - 2016-08-16
#### Changed
- Fixes a bug, that the episode summary is not displayed on the player page player.

## 0.6.6 - 2016-08-09
#### Changed
- Fixes a bug in the duration diplayed by the web player

## 0.6.5 - 2016-06-06
#### Changed
- Fixes a bug in paged feeds

## 0.6.3 - 2016-06-06
#### Changed
- Fixes a bug, when hosted on a subdomain

## 0.6.2 - 2016-06-06
#### Changed
- Improvements for paged feeds

## 0.6.1 - 2016-06-05
#### Changed
- Fixes a bug in item derivation for the feeds

## 0.6.0 - 2016-06-05
### Added
- Support for paged feeds, use the episodes_per_feed_page attribute in _config.yml!
### Changed
- Documatation update

## 0.5.3 - 2016-06-01
### Changed
- Nicer messages for the installer script

## 0.5.2 - 2016-06-01
### Changed
- Typos in the installer script got fixed
- Documentation update

## 0.5.0 - 2016-05-30
### Changed
- Fixes a bug for static asset installation
- Documentation update

## 0.4 - 2016-05-29
#### Changed
- Command line help update
- Documentation update
- Set up a demo instance as a documentation site

## 0.3 - 2016-05-28
#### Changed
- Project readme update
- Update Logo and license info
- Documentation update

## 0.2 - 2016-05-28
#### Added
- Glyphicons as supplied assets
- Default feeds
- Default imprint
#### Changed
- Documentation update
- Tranlate demo files to English
- Cleanup for the demo config
- Updated layouts to more relent version of Bootstrap
- Improved asset copier script
- Updated Disqus support
- Updated Flattr support
- Updated the Podcast Player
- Cleanup for installation script
- Name change to jekyll-octopod
- Updated the gemspec
- Added license info

## 0.1 - 2016-03-26
#### Changed
- Let's get started!
