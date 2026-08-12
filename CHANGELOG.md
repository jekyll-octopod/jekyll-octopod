# Changelog

## 0.18.2 - 2026-08-12

### Fixed

- `octopod update` deleted the *entire* `_layouts/` and `img/` directories outright, on the
  assumption that a legacy site's copies of those directories were 100% gem output. That's wrong
  whenever a site added its own files alongside the generic ones - a custom layout with no gem
  equivalent (found on a real site: slide-deck layouts for a `talks/` feature), or real content
  photos dropped into `img/` (found on another real site: ~150 blog-post screenshots), got silently
  deleted right along with the generic files. `update` now only removes filenames the
  `jekyll-octopod-bulma` theme gem actually ships in `_layouts/` and `assets/img/` (read from the
  installed gem itself, so this can't drift out of sync as its file list changes), and cleans up any
  directory left empty in the process - anything else in `_layouts/` or `img/` is left untouched.

## 0.18.1 - 2026-08-12

### Fixed

- The initial `jekyll-octopod-bulma` 0.1.0 publish went out with an empty gem package (no
  `_layouts`/`_includes`/`_sass`/`assets`), so any site resolving to it would fail to find the
  theme. Tightened the dependency to `~> 0.1.1`, the corrected republish, so `0.1.0` can never be
  resolved again.

## 0.18.0 - 2026-08-12

### Changed

- Extracted `assets/_layouts`, `assets/_includes` (sidebar layout, post/feed layouts and includes)
  and the vendored `podlove-player`, `subscribe-button`, and `img`/favicon assets out of this gem
  into a new gem-based theme, [jekyll-octopod-bulma](https://github.com/jekyll-octopod/jekyll-octopod-bulma)
  (a fork of [jekyll-bulma](https://github.com/jekyll-octopod/jekyll-bulma), not a runtime
  dependency of it). `_config.yml.sample`'s `theme:` now points at `jekyll-octopod-bulma`, and this
  gem depends on it instead of `jekyll-bulma` directly.
- `assets/` in this gem now only holds copy-once starter content: `index.md`, `imprint.md`, the demo
  post/episode, feed templates (`episodes.*.rss`, `feed.*.json`, `general_feed.xml`), `_config.yml.sample`,
  and `_sass/_overrides.scss` (still meant to be hand-edited per site). `octopod setup`/`update`'s copy
  loop is unchanged — it still copies everything under the gem's `assets/`, which is simply a much
  smaller set of files now.
- `octopod update` now also removes any leftover local copy of the files/directories that moved into
  the theme gem (`_layouts`, `podlove-player`, `subscribe-button`, `img`, `favicon.ico`,
  `apple-touch-icon-precomposed.png`, and the theme-owned `_includes/*.html`) — those would otherwise
  silently shadow the theme gem's current version forever, with no build error to point at it. Any
  `.md` file found along the way is always kept.
- `octopod update` also points your `Gemfile` and `_config.yml` at `jekyll-octopod-bulma` for you: it
  replaces an existing `gem 'jekyll-bulma', ...` line in place (any quote style/indentation/version
  constraint), or adds `jekyll-octopod-bulma` next to your `jekyll-octopod` line if there was no
  `jekyll-bulma` line to begin with, and rewrites `theme: jekyll-bulma` to
  `theme: jekyll-octopod-bulma` in `_config.yml`. Re-running `update` is a no-op once both are in
  place. Just run `octopod update` after upgrading — `bundle install` afterwards picks up the rest.

### Removed

- Dropped `.autotest` (ZenTest-era config for a test runner this gem hasn't used in years) and
  `materials/demo.png` (an old Bootstrap/Bootflat-themed screenshot, unreferenced anywhere and
  superseded twice over by the Bulma port and the fediverse switch).

### Fixed

- The default `rake`/`rake test` task pointed at a `test/all.rb` that hasn't existed for a long
  time (this gem's tests live in `spec/`, run via `rspec`) and errored immediately. `Rakefile` now
  defines `rake spec` via `RSpec::Core::RakeTask`, and that's the default task.
- `lib/jekyll/static_file.rb`'s `octopod_exclude` had a dead, unused `nested_files = %w[]` local.
- `README.md`'s logo image pointed at `assets/img/logo.jpg`, which just moved to
  jekyll-octopod-bulma in this same release — now points at the live docs site instead.
- The gemspec's `homepage` still pointed at the old `haslinger/jekyll-octopod` repo instead of the
  `jekyll-octopod` org; also dropped the long-dead `rubyforge_project` attribute (RubyForge shut
  down in 2014).

## 0.17.2 - 2026-08-11

### Fixed

- `PodcastPlayerPageGenerator` (`lib/jekyll/podcast_player_page_generator.rb`) built each episode's
  standalone player page at `players/<slug>/index.html` using `post.data['slug']` alone, with no
  date. That slug is derived purely from the filename's title portion, so two posts can legitimately
  share one (a recurring "Update"/"Q&A" episode, or two differently-titled posts that happen to share
  a filename word - found on panoptikum.io: `2017-02-12-search.markdown` and
  `2017-04-02-search.markdown`). Both resolved to the same destination and one silently vanished from
  the built site with no error, only a late "destination shared by multiple files" warning from
  Jekyll itself. Fixed: the earliest post with a given slug keeps the plain `players/<slug>/` path
  (so nothing changes for the common, non-colliding case); any later post sharing that slug now gets
  its date appended (`players/<slug>-<YYYYMMDD>/`) instead of being dropped.

## 0.17.1 - 2026-08-11

### Fixed

- The `{% icon %}` tag (`lib/jekyll/line_awesome.rb`) always rendered `class="las ..."` (the
  solid family), with no way to reach Line Awesome's other two icon families. This silently
  broke every brand icon (Twitter, Facebook, Apple, Google, Android, etc.) - those glyphs only
  exist in the `lab` (brands) family, and since `.las`/`.lar`/`.lab` carry equal CSS
  specificity, whichever is declared last in the compiled stylesheet (`.las`) always won even
  if `lab` were just added alongside it, not substituted. Surfaced while migrating
  panoptikum.io's old Font Awesome icon usage over to this tag. The tag's second (optional)
  argument now switches the whole family when it's exactly `las`, `lar` or `lab`
  (`{% icon la-twitter lab %}`), falling back to its old behavior (an appended modifier class
  such as `la-2x` or `la-spin`) for anything else, so existing usage keeps working unchanged.

## 0.17.0 - 2026-08-11

### Added

- New `octopod update` CLI command for bringing an existing site's scaffold files up to date with the
  currently installed jekyll-octopod version, without the all-or-nothing risk of `octopod setup`.
  Unlike `setup`, it never touches `_posts/`, `imprint.md`, `index.md` or the gem's demo
  `episodes/episode0.*` files — those are skipped outright, not just defaulted in the overwrite
  prompt, since `update` targets sites that are already live with real, hand-written content. It also
  scans every post under `_posts/` for the retired `{% podigee_player %}` tag (from the old Podigee
  integration, dropped when the self-hosted Podlove Web Player landed in 0.15.1) and rewrites it to
  `{% podlove_player %}` in place, printing which files it touched.

## 0.16.1 - 2026-08-11

### Fixed

- The commented-out navbar-color example in the scaffold's `assets/_sass/_overrides.scss` carried a
  specific real podcast's branding ("Swiss-Sided Dice", red/white) rather than reading as a generic
  example. Replaced it with a neutral steel-blue placeholder, uncommented so it's active out of the
  box, with the comment reworded to explain the CSS-custom-property mechanism instead of naming a
  podcast (and the stray "the way Bootstrap required" aside removed).
- That example only colored the navbar's resting state. Two related gaps, fixed alongside it:
  - The *currently active* nav item (`a.navbar-item.is-active`) didn't inherit the navbar's own
    hue/saturation/lightness at all — it reads a separate `--bulma-navbar-item-selected-*` set of
    properties that default to Bulma's own global link color, unrelated to the navbar override. Now
    pointed at the navbar's own values, with its own background/text lightness for a clearly
    distinguished "you are here" state.
  - The example's background was a literal color, so it didn't react to `prefers-color-scheme: dark`
    the way the rest of the (CSS-custom-property-driven) theme does. Left alone, dark mode swapped the
    resting nav items' text to something light (Bulma's own `--bulma-text-l`, meant for contrast
    against a dark page) while the navbar itself stayed exactly as light as in light mode — light text
    on a still-light bar. Added a `@media (prefers-color-scheme: dark)` override with a darker version
    of the same hue (verified 6.1:1 contrast against Bulma's dark-mode text color).

## 0.16.0 - 2026-08-11

### Changed

- **Breaking**: Replaced Twitter with the fediverse across the theme, since that's where the podcast
  audience actually is now. The `twitter_nick` config option (`assets/_config.yml.sample`) is gone;
  set `fediverse_url` to your profile's full URL (e.g. `https://podcasts.social/@my_account`) instead.
  The sidebar "Follow" button (`assets/_includes/sidebar.html`) now links there with a `rel="me"`
  attribute (so Mastodon can verify the link back to your site) and shows the derived `@user@instance`
  handle via the new `fediverse_handle` Liquid filter (`lib/jekyll/octopod_filters.rb`).
- **Breaking**: Removed the per-post "Tweet" quick-share button (`assets/_includes/post.html`) and the
  unused `tweet_us.html` include. Mastodon/the fediverse has no universal share-intent URL — every
  visitor's instance is different — so there's no equivalent to drop in, and adding a third-party
  cross-instance share helper would go against this project's own stance on external dependencies (see
  the now-removed `remove_external_dependencies.md`, which was Twitter-widget-specific and fully stale
  once Twitter itself was removed).
- **Breaking**: Removed the Twitter Card `player` meta tags (`twitter:card`, `twitter:site`, etc.) that
  let X/Twitter render an inline audio player for shared episode links — a Twitter-specific embed
  protocol, unrelated to linking a Twitter account, with no fediverse equivalent to replace it with.
  This left `_layouts/with_twitter_card.html` byte-identical to `_layouts/default.html`, so it's been
  deleted; `_layouts/post.html` now uses `layout: default` directly. Sites with custom pages set to
  `layout: with_twitter_card` need to switch to `layout: default`.

## 0.15.1 - 2026-08-10

### Fixed

- The Podlove Web Player's default theme has no UI element that displays `episode.subtitle`
  anywhere (verified against the player's own Redux state: the subtitle is correctly received and
  parsed, it's just never rendered by the stock theme, at any viewport width). `{% podlove_player %}`
  now folds the subtitle into the title it sends (`"Title - Subtitle"`) as a pragmatic workaround,
  so it's actually visible. The plain `subtitle` field is still sent alongside it, unused by the
  default theme today but available if a custom theme (or a future Podlove release) picks it up.

## 0.15.0 - 2026-08-10

### Changed

- **Breaking**: Replaced the Podigee Web Player with the [Podlove Web Player](https://podlove.org/podlove-web-player/)
  (`@podlove/web-player` 5.13.0, self-hosted from `assets/podlove-player/` — no external CDN). The
  `{% podigee_player %}` Liquid tag is gone; use `{% podlove_player %}` instead (same no-argument
  usage). `assets/podigee-player/` and `lib/jekyll/podigee_player_tag.rb` are removed, along with the
  `player_theme` config option (`assets/_config.yml.sample`) — Podlove v5 has no equivalent named-theme
  concept, so there's nothing to configure there.
- Sites still using the old `{% podigee_player page %}` syntax in post bodies (the `page` argument was
  always silently ignored by both the old and new tag) need to update to `{% podlove_player %}`.

### Fixed

- `PodcastPlayerPage` (the generator behind the standalone `/players/<slug>` pages, used for e.g.
  Twitter Card player embeds) never copied a post's `filesize` or `date` over to the generated page.
  This never mattered for the old Podigee integration, which didn't need either, but the new Podlove
  tag needs both (`audio[].size` and `publicationDate` are required fields in its config schema) — so
  audio downloads without explicit `filesize` front matter would have crashed trying to stat a
  nonexistent local file, and every publication date would have rendered empty. Both are now copied
  over correctly.

## 0.14.0 - 2026-08-10

### Changed

- Updated the bundled Podigee Podcast Player (`assets/podigee-player/`) to the latest version served
  from Podigee's CDN: `podigee-podcast-player.html`, `javascripts/podigee-podcast-player.js` and
  `-embed.js`, `stylesheets/app.css`, the icon font (`fonts/podigee-podcast-player.*`), and the
  `default`/`default-dark`/`legacy`/`minimal` theme templates. The `default` theme in particular is
  now considerably richer (search, transcripts, Chromecast, playlist, speed selector, share panel)
  than the ~2018 snapshot that was vendored before. Precompressed `.gz` variants regenerated to match.

### Removed

- **Breaking**: Dropped support for the `republica` Podigee player theme. Podigee discontinued it
  upstream — it's gone from their current source tree and CDN (`403` on every path checked). Removed
  from `PLAYER_THEMES` in `lib/jekyll/podigee_player_tag.rb`, from the `player_theme` comment in
  `assets/_config.yml.sample`, and deleted the vendored `assets/podigee-player/themes/republica/`
  files. Sites with `player_theme: republica` set will fall back to the `default` theme.
- Removed the obsolete `themes/*/variables.css` files (default, default-dark, legacy). The current
  Podigee build consolidated per-theme variables into a single `index.css` per theme; the separate
  `variables.css` split no longer exists upstream (`403` on the CDN for all themes, not just
  `republica`).

## 0.13.0 - 2026-08-10

### Changed

- Ported the remaining installer-copied templates from Bootstrap 3 to Bulma classes and Line Awesome
  icons, completing the theme migration started in 0.10.0/0.11.0: `assets/_layouts/default.html`,
  `with_twitter_card.html`, `page.html`, and `assets/_includes/post_header.html`, `post.html`,
  `sidebar.html`, `disqus_count.html`. Sites created via `octopod setup` now get Bulma-shaped markup
  (navbar, sidebar box, feed/directory lists, post headers) instead of the old Bootstrap 3 output.
- **Breaking**: The `navigation_list` Liquid filter's rendered output changed shape. It used to emit
  Bootstrap-style `<li><a class="active">...</a></li>` items; it now emits flat Bulma navbar items,
  `<a class="navbar-item is-active">...</a>`, with no `<li>` wrapper — Bulma's navbar has no `<ul>`
  list structure. Sites with custom navbar markup built around the old `<li>`-wrapped shape will need
  to adjust. The `navigation_list_item` helper itself is unchanged and still returns `<li>`-wrapped
  items for callers that need a real list (e.g. a custom `<ol>`/`<ul>` of pages) — only `navigation_list`
  (the navbar-specific filter) switched to the new `navbar_item` helper internally.
- Removed the dead `<script>` tag loading MathJax from an external CDN in the installer's example
  usage; MathJax support itself was already removed from the gem back in 0.9.6 (2018-07-11), this
  just cleans up a leftover reference.

### Removed

- Removed the `talk_list` Liquid filter (`lib/jekyll/octopod_filters.rb`). It was unused by any
  bundled template and still built a Bootstrap 3 dropdown menu (`data-toggle="dropdown"`, needs
  `bootstrap.min.js`, which no longer ships), so it was already broken for any site that did call it.

### Fixed

- `bin/octopod` crashed outright on Ruby 3.2+ (including the 4.0.6 this project now targets):
  `File.exists?` was used in five places, but that method was removed from modern Ruby (`File.exist?`
  is the replacement, deprecated since 2.1). Also, several `FileUtils.cp`/`mkdir` calls passed an
  options hash as a positional third argument (`{verbose: true}`), which newer `FileUtils` no longer
  accepts — it needs real keyword arguments (`verbose: true`). `octopod setup`, `episode`, and `deploy`
  all work again as a result.
- Fixed a typo in `assets/_sass/_overrides.scss` (`btn small, .btn small` — missing a leading dot on
  the bare `btn` selector, and both were dead since the Bulma port dropped Bootstrap's `.btn` class
  in favor of `.button`) — now `.button small`.
- Restored the Ubuntu webfont as the site's body font. It was silently broken by 0.10.0's Sass
  `@import`→`@use` migration in jekyll-bulma (`$font-family-base` stopped having any effect once Sass
  variables became module-scoped instead of global) and never actually re-fixed for the current
  `--bulma-body-family` custom property. Added an active override in `assets/_sass/_overrides.scss`;
  also updated its commented-out example navbar theme from Bootstrap `.navbar-default` overrides to
  the Bulma CSS-custom-property equivalent, since the old example no longer matched anything real.

## 0.12.0 - 2026-08-09

### Removed

- **Breaking**: Removed Flattr integration (Flattr shut down in 2023). Deleted the `flattr_button`, `flattr_loader_options`, `flattr_rss`, and `flattr_atom` Liquid filters (`lib/jekyll/flattr_filters.rb`), the `flattr_loader.html` include, and all `flattr_*` `_config.yml` keys. Sites still setting `flattr_uid` etc. can remove those keys; the filter calls in `sidebar.html`, `post.html`, `feed.xml`, `general_feed.xml`, and the `default.html`/`with_twitter_card.html` layouts are gone, so no template changes are needed on the consuming site's side.

## 0.11.1 - 2026-08-02

### Fixed

- Fixed a `_site/episodes.*.rss` destination-conflict warning on `jekyll build`/`serve`: the on-disk feed marker files (`assets/episodes.mp3.rss` etc.) and `paged_feed_page_generator.rb`'s generated pages both targeted the same output path. `update_config.rb` now excludes the marker files via `site.exclude` so the generator remains the sole writer.

## 0.11.0 - 2026-08-02

### Changed

- **Breaking**: Ported the `{% icon %}` Liquid tag from Font Awesome to Line Awesome (bundled with jekyll-bulma). Icon names now use the `la-` prefix instead of `fa-`, e.g. `{% icon la-camera-retro %}` instead of `{% icon fa-camera-retro %}`.

## 0.10.0 - 2026-08-02

### Changed

- Updated all dependencies; now requires Jekyll ~> 4.4.
- Switched the bundled CSS/theme from jekyll-bootflat to [jekyll-bulma](https://github.com/jekyll-octopod/jekyll-bulma).

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
