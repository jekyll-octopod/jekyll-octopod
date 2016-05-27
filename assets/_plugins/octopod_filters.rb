#require 'erb'
require 'uri'
require 'digest/sha1'

module Jekyll
  module OctopodFilters
    JSON_ENTITIES = { '&' => '\u0026', '>' => '\u003E', '<' => '\u003C', "'" => '\u0027' }

    # Escapes  some text for CDATA
    def cdata_escape(input)
      input.gsub(/<!\[CDATA\[/, '&lt;![CDATA[').gsub(/\]\]>/, ']]&gt;')
    end

    # Escapes HTML entities in JSON strings.
    # More or less a copy of the equivalent method in Active Support.
    # https://github.com/rails/rails/tree/master/activesupport
    def j(str)
      str.to_s.gsub(/[&"><']/) { |e| JSON_ENTITIES[e] }
    end

    # Replaces relative urls with full urls
    #
    #   {{ "about.html" | expand_urls }}             => "/about.html"
    #   {{ "about.html" | expand_urls:site.url }}  => "http://example.com/about.html"
    def expand_urls(input, url='')
      url ||= '/'
      input.gsub /(\s+(href|src)\s*=\s*["|']{1})(\/[^\"'>]*)/ do
        $1+url+$3
      end
    end

    # Removes scripts tag and audio tags in multiline moderator
    def remove_script_and_audio(input)
      input.gsub(/<audio.*audio>/m, '').gsub(/<script.*script>/m, '')
    end

    def http_only(input)
      input.gsub(/https/,"http")
    end

    # Formats a Time to be RSS compatible like "Wed, 15 Jun 2005 19:00:00 GMT"
    #
    #   {{ site.time | time_to_rssschema }}
    def time_to_rssschema(time)
      time.strftime("%a, %d %b %Y %H:%M:%S %z")
    end

    # Returns the first argument if it's not nil or empty otherwise it returns
    # the second one.
    #
    #   {{ post.author | otherwise:site.author }}
    def otherwise(first, second)
      first = first.to_s
      first.empty? ? second : first
    end

    # Returns the value of a given hash. Is no key as second parameter given, it
    # trys first "mp3", than "m4a" and than it will return a more or less random
    # value.
    #
    #   {{ post.audio | audio:"m4a" }} => "my-episode.m4a"
    def audio(hsh, key = nil)
      if key.nil?
        hsh['mp3'] ? hsh['mp3'] : hsh['m4a'] ? hsh['m4a'] : hsh.values.first
      else
        hsh[key]
      end
    end

    # Returns the MIME-Type of a given file format.
    #
    #   {{ "m4a" | mime_type }} => "audio/mp4a-latm"
    def mime_type(format)
      types = {
        'mp3'  => 'mpeg',
        'm4a'  => 'mp4a-latm',
        'ogg'  => 'ogg; codecs=vorbis',
        'opus' => 'ogg; codecs=opus'
      }

      "audio/#{types[format]}"
    end

    # Returns the size of a given file in bytes. If there is just a filename
    # without a path, this method assumes that the file is an episode audio file
    # which lives in /episodes.
    #
    #   {{ "example.m4a" | file_size }} => 4242
    def file_size(path, rel = nil)
      return 0 if path.nil?
      path = path =~ /\// ? path : File.join('episodes', path)
      path = rel + path if rel
      File.size(path)
    end

    # Returns a slug based on the id of a given page.
    #
    #   {{ page | slug }} => '2012_10_02_octopod'
    def slug(page)
      page['id'][1..-1].gsub('/', '_')
    end

    # Splits a chapter, like it is written to the post YAML front matter into
    # the components 'start' which refers to a single point in time relative to
    # the beginning of the media file nad 'title' which defines the text to be
    # the title of the chapter.
    #
    #   {{ '00:00:00.000 Welcome to Octopod!' | split_chapter }}
    #     => { 'start' => '00:00:00.000', 'title' => 'Welcome to Octopod!' }
    #
    #   {{ '00:00:00.000 Welcome to Octopod!' | split_chapter:'title' }}
    #     => 'Welcome to Octopod!'
    #
    #   {{ '00:00:00.000 Welcome to Octopod!' | split_chapter:'start' }}
    #     => '00:00:00.000'
    def split_chapter(chapter_str, attribute = nil)
      attributes = chapter_str.split(/ /, 2)
      return nil unless attributes.first.match(/\A(\d|:|\.)+\z/)

      if attribute.nil?
        { 'start' => attributes.first, 'title' => attributes.last }
      else
        attribute == 'start' ? attributes.first : attributes.last
      end
    end

    # Returns an <audio>-tag for a given page with <source>-tags in it for every
    # audio file in the page's YAML front matter.
    #
    #   {{ page | audio_tag:site }}
    def audio_tag(page, site)
      out = "<audio>" + page['audio'].map { |format, filename|
        %Q{<source src="#{site['url']}/episodes/#{ERB::Util.url_encode(filename)}" type="#{mime_type(format)}"></source>}
      }.join("\n") + "\n</audio>\n"
    end


    # Returns the web player moderator tag for the episode of a given page.
    #
    #   {{ page | web_player_moderator:site }}
    def web_player_moderator(page, site)
      return if page['audio'].nil?
      out = %Q{<div class="podlove-player-wrapper">}
      out = out + %Q{  <audio data-podlove-web-player-source="/players/#{page['slug']}/index.html">\n}
      out = out + "    <source src='episodes/#{page['audio']['mp3']}' type='audio/mp3'>\n"
      out = out + "  </audio>\n"
      out = out + "</div>\n"
      out = out + "<script>$('audio').podlovewebplayer();</script>\n"
    end


    # Returns the web player for the episode of a given page.
    #
    #   {{ page | web_player:site }}
    def web_player(page, site)
      return if page['audio'].nil?

      options = {
        alwaysShowHours: 'true',
        startVolume: '0.8',
        width: 'auto',
        summaryVisible: 'true',
        timecontrolsVisible: 'true',
        chaptersVisible: 'true',
        sharebuttonsVisible: 'true'
      }

      simple_keys = %w[]

      if sitehash = site.posts.first.site.config.dup
        sitehash.delete('title')
        sitehash.delete('subtitle')
        options = options.merge(sitehash)
      end
      options = options.merge(page)
      out = audio_tag(page, sitehash)
    end

    # Returns the web player for the episode of a given page.
    #
    #   {{ page | web_player_script_tag:site }}
    def web_player_script_tag(page, site)
      return if page['audio'].nil?

      options = {
        alwaysShowHours: 'true',
        startVolume: '0.8',
        width: 'auto',
        summaryVisible: 'true',
        timecontrolsVisible: 'true',
        chaptersVisible: 'true',
        sharebuttonsVisible: 'true'
      }

      simple_keys = %w[]

      if sitehash = site.posts.first.site.config.dup
        sitehash.delete('title')
        sitehash.delete('subtitle')
        options = options.merge(sitehash)
      end
      options = options.merge(page)

      out = "<script>\n$('audio').podlovewebplayer("
      out << { poster: sitehash['url'] + (options['episode_cover'] || '/img/logo-360x360.png'),
               subtitle: options['subtitle'],
               title: options['title'],
               alwaysShowHours: options['alwaysShowHours'],
               startVolume: options['startVolume'],
               width: options['width'],
               summaryVisible: options['summaryVisible'],
               timecontrolsVisible: options['timecontrolsVisible'],
               chaptersVisible: options['chaptersVisible'],
               sharebuttonsVisible: options['sharebuttonsVisible'],
               show: { title: site['title'],
                       subtitle: site['subtitle'],
                       summary: site['description'],
                       poster: sitehash['url'] + '/img/logo-360x360.png',
                       url: sitehash['url'] },
               chapters: options['chapters'].map {|chapter| split_chapter(chapter)},
               downloads: [
                 { assetTitle: options['title'],
                   size: file_size(page['audio']['mp3']),
                   downloadUrl: sitehash["url"] + "/episodes/" + page['audio']['mp3'] },
               ],
               summary: options['summary'],
               duration: string_of_duration(options['duration']),
               permalink: sitehash['url'] + page['url'],
               activeTab: "chapters"
             }.to_json
      out << ")\n</script>"
    end

    # Gets a number of seconds and returns an human readable duration string of
    # it.
    #
    #   {{ 1252251 | string_of_duration }} => "00:03:13"
    def string_of_duration(duration)
      seconds = duration.to_i
      minutes = seconds / 60
      hours   = minutes / 60

      "#{"%02d" % hours}:#{"%02d" % (minutes % 60)}:#{"%02d" % (seconds % 60)}"
    end

    # Gets a number of bytes and returns an human readable string of it.
    #
    #   {{ 1252251 | string_of_size }} => "1.19M"
    def string_of_size(bytes)
      bytes = bytes.to_i.to_f
      out = '0'
      return out if bytes == 0.0

      jedec = %w[b K M G]
      [3, 2, 1, 0].each { |i|
        if bytes > 1024 ** i
          out = "%.1f#{jedec[i]}" % (bytes / 1024 ** i)
          break
        end
      }

      return out
    end

    # Returns the host a given url
    #
    #   {{ 'https://github.com/pattex/octopod' | host_from_url }} => "github.com"
    def host_from_url(url)
      URI.parse(url).host
    end

    # Generates the config for disqus integration
    # If a page object is given, it generates the config variables only for this
    # page. Otherwise it generate only the global config variables.
    #
    #   {{ site | disqus_config }}
    #   {{ site | disqus_config:page }}
    def disqus_config(site, page = nil)
      if page
        disqus_vars = {
          'disqus_identifier'  => page['url'],
          'disqus_url'         => "#{site['url']}#{page['url']}",
          'disqus_category_id' => page['disqus_category_id'] || site['disqus_category_id'],
          'disqus_title'       => j(page['title'] || site['site'])
        }
      else
        disqus_vars = {
          'disqus_developer'   => site['disqus_developer'],
          'disqus_shortname'   => site['disqus_shortname']
        }
      end

      disqus_vars.delete_if { |_, v| v.nil? }
      disqus_vars.map { |k, v| "var #{k} = '#{v}';" }.compact.join("\n")
    end

    # Returns the hex-encoded hash value of a given string. The optional
    # second argument defines the length of the returned string.
    #
    #   {{ "Octopod" | sha1 }} => "8b20a59c"
    #   {{ "Octopod" | sha1:23 }} => "8b20a59c8e2dcb5e1f845ba"
    def sha1(str, lenght = 8)
      sha1 = Digest::SHA1.hexdigest(str)
      sha1[0, lenght.to_i]
    end

    # Returns a, ready to use, navigation list of all pages that have
    # <tt>navigation</tt> set in their YAML front matter. The list is sorted by
    # the value of <tt>navigation</tt>.
    #
    #   {{ site | navigation_list:page }}
    def navigation_list(site, page)
      pages = site['pages'].select { |p|
        p.data['navigation'] && p.data['title']
      }.sort_by { |p| p.data['navigation'] }

      list =  ['<ul class="nav navbar-nav">']
      list << pages.map { |p|
        active = (p.url == page['url']) || (page.has_key?('next') && File.join(p.dir, p.basename) == '/index')
        navigation_list_item(File.join(site['url'], p.url), p.data['title'], active)
      }
      list << ['</ul>']

      list.join("\n")
    end

    def navigation_list_item(url, title, active = false)
      a_class = active ? ' class="active"' : ''
      %Q{<li#{a_class}><a #{a_class} href="#{url}">#{title}</a></li>}
    end

    # Returns an array of all episode feeds named by the convetion
    # 'episodes.<episode_file_format>.rss' within the root directory. Also it
    # contains all additional feeds specified by 'additional_feeds' in the
    # '_config.yml'. If an 'episode_file_format' or key of 'additional_feeds'
    # equals the optional parameter 'except', it will be skipped.
    #
    #   episode_feeds(site, except = nil) =>
    #   [
    #     ["m4a Episode RSS-Feed", "/episodes.m4a.rss"],
    #     ["mp3 Episode RSS-Feed", "/episodes.mp3.rss"],
    #     ["Torrent Feed m4a", "http://bitlove.org/octopod/octopod_m4a/feed"],
    #     ["Torrent Feed mp3", "http://bitlove.org/octopod/octopod_mp3/feed"]
    #   ]
    def episode_feeds(site, except = nil)
      feeds = []

      if site['episode_feed_formats']
        site['episode_feed_formats'].map { |f|
         feeds << ["#{f} Episode RSS-Feed", "#{site['url']}/episodes.#{f}.rss"] unless f == except
        }
      end
      if site['additional_feeds']
        site['additional_feeds'].each { |k, v|
          feeds << [k.gsub('_', ' '), v] unless k == except
        }
      end

      feeds
    end

    # Returns HTML links to all episode feeds named by the convetion
    # 'episodes.<episode_file_format>.rss' within the root directory. Also it
    # returns all additional feeds specified by 'additional_feeds' in the
    # '_config.yml'. If an 'episode_file_format' or key of 'additional_feeds'
    # equals the optional parameter 'except', it will be skipped.
    #
    #   {{ site | episode_feeds_html:'m4a' }} =>
    #   <link rel="alternate" type="application/rss+xml" title="mp3 Episode RSS-Feed" href="/episodes.mp3.rss" />
    #   <link rel="alternate" type="application/rss+xml" title="Torrent Feed m4a" href="http://bitlove.org/octopod/octopod_m4a/feed" />
    #   <link rel="alternate" type="application/rss+xml" title="Torrent Feed mp3" href="http://bitlove.org/octopod/octopod_mp3/feed" />
    def episode_feeds_html(site, except = nil)
      episode_feeds(site, except).map { |f|
        %Q{<link rel="alternate" type="application/rss+xml" title="#{f.first || f.last}" href="#{f.last}" />}
      }.join("\n")
    end

    # Returns RSS-XML links to all episode feeds named by the convetion
    # 'episodes.<episode_file_format>.rss' within the root directory. Also it
    # returns all additional feeds specified by 'additional_feeds' in the
    # '_config.yml'. If an 'episode_file_format' or key of 'additional_feeds'
    # equals the optional parameter 'except', it will be skipped.
    #
    #   {{ site | episode_feeds_rss:'m4a' }} =>
    #   <atom:link rel="alternate" href="/episodes.mp3.rss" type="application/rss+xml" title="mp3 Episode RSS-Feed"/>
    #   <atom:link rel="alternate" href="http://bitlove.org/octopod/octopod_m4a/feed" type="application/rss+xml" title="Torrent Feed m4a"/>
    #   <atom:link rel="alternate" href="http://bitlove.org/octopod/octopod_mp3/feed" type="application/rss+xml" title="Torrent Feed mp3"/>
    def episode_feeds_rss(site, except = nil)
      episode_feeds(site, except).map { |f|
        %Q{<atom:link rel="alternate" href="#{f.last}" type="application/rss+xml" title="#{f.first || f.last}"/>}
      }.join("\n")
    end

  end
end

Liquid::Template.register_filter(Jekyll::OctopodFilters)
