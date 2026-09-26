require 'fileutils'
require 'json'
require 'net/http'
require 'rexml/document'
require 'time'
require 'uri'
require 'yaml'
require 'octopod/version'

module Jekyll
  class Octopod
    # Creates a brand new jekyll-octopod site from an existing podcast RSS feed: channel metadata
    # goes into _config.yml, every <item> becomes one post in _posts/, and every enclosure (plus
    # episode images and WebVTT transcripts, where the feed has them) is downloaded next to it, so
    # the new site hosts everything itself - no 'download_url' or 'filesize' front matter needed,
    # the same setup 'octopod setup' ships for a fresh site.
    #
    # With download_enclosures: false, only the audio stays where it is: _config.yml's
    # 'download_url' is set to the directory all enclosure URLs share, each post's 'audio' holds
    # the rest of its URL, and 'filesize' comes from the feed (or a HEAD request) - the same setup
    # as a site that hosts its audio remotely by hand.
    #
    # Used by 'octopod import <feed url> [target directory]'. Network access goes through a
    # fetcher object (HttpFetcher by default) so specs can swap in a fake one.
    class Importer
      GEM_ROOT = File.expand_path('../..', __dir__)

      # Namespace URIs by the prefix they're conventionally used with. Matched by URI, never by
      # prefix, since feeds are free to bind any prefix they like. iTunes has been seen in the
      # wild with both spellings of its DTD path.
      NAMESPACES = {
        'rss'     => [nil, ''],
        'itunes'  => ['http://www.itunes.com/dtds/podcast-1.0.dtd', 'http://www.itunes.com/DTDs/Podcast-1.0.dtd'],
        'content' => ['http://purl.org/rss/1.0/modules/content/'],
        'atom'    => ['http://www.w3.org/2005/Atom'],
        'psc'     => ['http://podlove.org/simple-chapters'],
        'podcast' => ['https://podcastindex.org/namespace/1.0']
      }.freeze

      # Enclosure MIME types mapped to the format keys OctopodFilters#mime_type understands -
      # anything else (video podcasts, mostly) has no working feed/player support in octopod.
      FORMATS_BY_MIME = {
        'audio/mpeg' => 'mp3', 'audio/mp3' => 'mp3',
        'audio/mp4' => 'm4a', 'audio/x-m4a' => 'm4a', 'audio/m4a' => 'm4a', 'audio/mp4a-latm' => 'm4a', 'audio/aac' => 'm4a',
        'audio/ogg' => 'ogg', 'audio/vorbis' => 'ogg', 'audio/opus' => 'opus'
      }.freeze
      FORMATS = %w[mp3 m4a ogg opus].freeze
      IMAGE_EXTENSIONS = %w[jpg jpeg png gif webp].freeze

      # Config lines in _config.yml.sample that are placeholders pointing at someone else's
      # accounts - harmless on a demo site, wrong on a real imported one, so they get commented out.
      PLACEHOLDER_CONFIG_KEYS = %w[itunes_url fediverse_url].freeze

      attr_reader :target, :warnings

      def initialize(source, target = nil, site_url: nil, limit: nil, force: false, download_enclosures: true,
                     fetcher: HttpFetcher.new, gem_spec: nil, out: $stdout)
        @source = source
        @target = target
        @site_url = site_url
        @limit = limit
        @force = force
        @download_enclosures = download_enclosures
        @fetcher = fetcher
        @gem_spec = gem_spec
        @out = out
        @warnings = []
      end

      def run
        channel, items = load_feed
        @target ||= File.join(Dir.pwd, slugify(text(channel, 'rss', 'title')) || 'podcast')

        episodes = items.map { |item| parse_item(item) }.sort_by { |episode| episode[:date] }
        episodes = episodes.last(@limit) if @limit
        assign_slugs(episodes)
        @download_url = enclosure_base_url(episodes) unless @download_enclosures
        prepare_target

        say "===== Creating site in #{@target} ====="
        copy_site_skeleton
        write_gemfile
        channel_image = import_channel_image(channel)
        write_config(channel)

        formats = []
        episodes.each_with_index do |episode, index|
          say "", "[#{index + 1}/#{episodes.size}] #{episode[:title]}"
          formats << episode[:format] if import_episode(episode, channel_image)
        end
        formats.uniq.each { |format| write_feed_marker(format) }

        say "", "===== Imported #{episodes.size} episode(s) into #{@target} ====="
        say "Review _config.yml (url, license, deploy settings) and imprint.md before publishing."
        unless @warnings.empty?
          say "", "Warnings:"
          @warnings.each { |warning| say "  - #{warning}" }
        end
        self
      end

      private

      # --- Feed -------------------------------------------------------------------------------

      # Returns the channel element of the first feed page plus the items of every page,
      # following atom:link rel="next" the way jekyll-octopod's own paged feeds are linked.
      def load_feed
        items = []
        seen = {}
        channel = nil
        location = @source

        while location && !seen[location]
          seen[location] = true
          say "Reading feed #{location}"
          document = REXML::Document.new(read_source(location))
          page_channel = document.root && child(document.root, 'rss', 'channel')
          raise ArgumentError, "#{location} is not an RSS feed (no <rss><channel> found)" unless page_channel

          channel ||= page_channel
          items.concat(children(page_channel, 'rss', 'item'))
          next_link = children(page_channel, 'atom', 'link').find { |link| link.attributes['rel'] == 'next' }
          location = next_link && absolute_url(next_link.attributes['href'], location)
        end

        [channel, items]
      end

      def read_source(location)
        File.file?(location) ? File.read(location) : @fetcher.read(location)
      end

      def parse_item(item)
        subtitle = text(item, 'itunes', 'subtitle')
        title = text(item, 'rss', 'title') || text(item, 'itunes', 'title') || 'untitled'
        # jekyll-octopod's own feed renders "<title> - <subtitle>" into <title>; undo that so a
        # round trip doesn't end up with the subtitle shown twice.
        title = title.delete_suffix(" - #{subtitle}") if subtitle && title.length > subtitle.length + 3

        enclosure = child(item, 'rss', 'enclosure')
        enclosure_url = enclosure && enclosure.attributes['url'].to_s.strip
        enclosure_url = nil if enclosure_url&.empty?

        { title: title,
          link: text(item, 'rss', 'link'),
          subtitle: subtitle,
          summary: text(item, 'itunes', 'summary'),
          date: parse_date(text(item, 'rss', 'pubDate')),
          author: text(item, 'itunes', 'author'),
          explicit: normalize_explicit(text(item, 'itunes', 'explicit')),
          duration: normalize_duration(text(item, 'itunes', 'duration')),
          tags: split_list(text(item, 'itunes', 'keywords')) + children(item, 'rss', 'category').map { |c| c.text.to_s.strip },
          guid: text(item, 'rss', 'guid'),
          enclosure_url: enclosure_url,
          enclosure_length: enclosure && enclosure.attributes['length'].to_i,
          format: enclosure_url && format_for(enclosure.attributes['type'], enclosure_url),
          image_url: child(item, 'itunes', 'image')&.attributes&.[]('href'),
          chapters: children(child(item, 'psc', 'chapters'), 'psc', 'chapter').map do |chapter|
            "#{normalize_timestamp(chapter.attributes['start'])} #{chapter.attributes['title']}"
          end,
          chapters_url: children(item, 'podcast', 'chapters').first&.attributes&.[]('url'),
          transcript_url: children(item, 'podcast', 'transcript')
                            .find { |t| t.attributes['type'].to_s.start_with?('text/vtt') }&.attributes&.[]('url'),
          body: text(item, 'content', 'encoded') || text(item, 'rss', 'description') || '' }
      end

      # --- Site skeleton ----------------------------------------------------------------------

      def prepare_target
        if Dir.exist?(@target) && !Dir.empty?(@target) && !@force
          raise ArgumentError, "#{@target} already exists and is not empty - pick another directory, " \
                               "or pass --force to import into it anyway (already downloaded media is kept)"
        end
        FileUtils.mkdir_p(@target)
      end

      # Same files 'octopod setup' copies, minus the demo episode (post, audio, feed markers):
      # the feed markers are written per format actually found in the imported feed instead.
      def copy_site_skeleton
        assets = File.join(GEM_ROOT, 'assets')
        Dir.glob(File.join(assets, '**', '*'), File::FNM_DOTMATCH).sort.each do |file|
          relative = file.delete_prefix(assets + '/')
          next if %w[. ..].include?(File.basename(relative))
          next if relative == '_config.yml.sample' || relative.match?(/\Aepisodes\.\w+\.rss\z/)
          next if relative.start_with?('_posts/', 'episodes/')

          destination = File.join(@target, relative)
          if File.directory?(file)
            FileUtils.mkdir_p(destination)
          else
            FileUtils.mkdir_p(File.dirname(destination))
            FileUtils.cp(file, destination)
          end
        end
        FileUtils.mkdir_p(File.join(@target, '_posts'))
        FileUtils.mkdir_p(File.join(@target, 'episodes'))
      end

      def write_gemfile
        path = File.join(@target, 'Gemfile')
        return if File.exist?(path)

        bulma = gem_spec&.dependencies&.find { |d| d.name == 'jekyll-octopod-bulma' }&.requirement&.to_s
        File.write(path, <<~GEMFILE)
          source "https://rubygems.org"
          gem 'jekyll', '~> 4.4'
          gem 'jekyll-sass-converter', '~> 3.0'

          group :jekyll_plugins do
            gem 'jekyll-octopod', '~> #{VERSION::STRING}'
            gem 'jekyll-octopod-bulma'#{bulma ? ", '#{bulma}'" : ''}
          end
        GEMFILE
      end

      def gem_spec
        @gem_spec ||= begin
          Gem::Specification.find_by_name('jekyll-octopod')
        rescue Gem::MissingSpecError
          nil
        end
      end

      # Edits _config.yml.sample line by line rather than dumping a fresh YAML hash, so the
      # sample's explanatory comments survive into the new site.
      def write_config(channel)
        config = File.read(File.join(GEM_ROOT, 'assets', '_config.yml.sample'))
        owner = child(channel, 'itunes', 'owner')
        email = text(owner, 'itunes', 'email') || text(channel, 'rss', 'managingEditor')&.sub(/\s*\(.*\)\s*\z/, '')
        # podcast:license names the actual license (with a link to it), <copyright> often just the
        # rights holder - so the former wins where a feed has both.
        license_element = child(channel, 'podcast', 'license')
        license = text(channel, 'podcast', 'license') || text(channel, 'rss', 'copyright')
        license_url = license_element&.attributes&.[]('url')
        categories = children(channel, 'itunes', 'category').map { |c| c.attributes['text'] }.compact

        values = {
          'title'             => text(channel, 'rss', 'title'),
          'url'               => @site_url,
          'subtitle'          => text(channel, 'itunes', 'subtitle'),
          'description'       => text(channel, 'rss', 'description') || text(channel, 'itunes', 'summary'),
          'author'            => text(channel, 'itunes', 'author') || text(owner, 'itunes', 'name'),
          'email'             => email,
          'keywords'          => split_list(text(channel, 'itunes', 'keywords')),
          'itunes_categories' => categories,
          'language'          => text(channel, 'rss', 'language')&.split(/[-_]/)&.first&.downcase,
          'explicit'          => normalize_explicit(text(channel, 'itunes', 'explicit')),
          'license'           => license,
          'license_url'       => license_url,
          'download_url'      => @download_url
        }
        values.each do |key, value|
          # Empty lists still replace the sample's placeholder keywords/categories.
          next if value.nil? || (value.is_a?(String) && value.empty?)
          config = config.sub(/^(# )?#{key}:.*$/) { "#{key}: #{JSON.generate(value)}" }
        end

        comment_out = PLACEHOLDER_CONFIG_KEYS.dup
        # The sample's CC BY 4.0 link and badge would claim a license the feed never granted.
        if license && license != 'CC BY 4.0'
          comment_out << 'license_image_url'
          comment_out << 'license_url' unless license_url
        end
        comment_out.each { |key| config = config.sub(/^#{key}:/, "# #{key}:") }

        File.write(File.join(@target, '_config.yml'), config)
      end

      def write_feed_marker(format)
        File.write(File.join(@target, "episodes.#{format}.rss"), "---\nlayout: feed\nformat: #{format}\n---\n")
      end

      # The theme hardcodes assets/img/logo-itunes.jpg (feeds) and assets/img/logo-360x360.png
      # (sidebar, player poster), so the channel image has to land under exactly those names.
      # Converting/resizing needs ImageMagick; without it, the image is only used where its
      # format already matches the expected file extension. The download itself is kept as
      # logo-original.* - a full-size source to derive other sizes from later, and what lets a
      # --force re-run skip downloading it again.
      def import_channel_image(channel)
        url = child(channel, 'itunes', 'image')&.attributes&.[]('href') ||
              text(child(channel, 'rss', 'image'), 'rss', 'url')
        return nil unless url

        url = absolute_url(url, @source)
        img_dir = File.join(@target, 'assets', 'img')
        FileUtils.mkdir_p(img_dir)
        original = File.join(img_dir, "logo-original.#{image_extension(url)}")
        return url unless download(url, original, label: 'podcast logo')

        type = sniff_image_type(original)
        if (magick = imagemagick)
          converted = system(*magick, original, File.join(img_dir, 'logo-itunes.jpg'), err: File::NULL) &&
                      system(*magick, original, '-resize', '360x360', File.join(img_dir, 'logo-360x360.png'), err: File::NULL)
          warn_about "ImageMagick couldn't convert the podcast logo (#{url}) - check assets/img/." unless converted
        elsif type == 'jpg'
          FileUtils.cp(original, File.join(img_dir, 'logo-itunes.jpg'))
          warn_about "Podcast logo is a JPEG and ImageMagick isn't installed - assets/img/logo-360x360.png " \
                     "still shows the theme's default logo."
        elsif type == 'png'
          FileUtils.cp(original, File.join(img_dir, 'logo-360x360.png'))
          warn_about "Podcast logo is a PNG and ImageMagick isn't installed - assets/img/logo-itunes.jpg " \
                     "(used in feeds) still shows the theme's default logo."
        else
          warn_about "Podcast logo saved as #{original.delete_prefix(@target + '/')}, but couldn't be converted " \
                     "(install ImageMagick) - the theme's default logos are still in use."
        end
        url
      end

      def imagemagick
        %w[magick convert].each do |command|
          return [command] if system(command, '-version', out: File::NULL, err: File::NULL)
        end
        nil
      rescue SystemCallError
        nil
      end

      # --- Episodes ---------------------------------------------------------------------------

      # Returns true if the episode ended up with a local audio file.
      def import_episode(episode, channel_image)
        slug = episode[:slug]
        front_matter = { 'title' => episode[:title] }
        front_matter['subtitle'] = episode[:subtitle] if episode[:subtitle]
        front_matter['date'] = episode[:date].strftime('%Y-%m-%d %H:%M:%S %z')
        front_matter['layout'] = 'post'
        front_matter['author'] = episode[:author] if episode[:author]
        front_matter['explicit'] = episode[:explicit] if episode[:explicit]
        front_matter['duration'] = episode[:duration] if episode[:duration]

        audio_file = nil
        if episode[:enclosure_url]
          enclosure_url = absolute_url(episode[:enclosure_url], @source)
          if FORMATS.include?(episode[:format]) && @download_url
            audio_file = enclosure_url.delete_prefix("#{@download_url}/")
            say "  audio: linking #{enclosure_url}"
            size = enclosure_size(episode, enclosure_url)
            front_matter['filesize'] = { episode[:format] => size } if size
          elsif FORMATS.include?(episode[:format])
            audio_file = "#{slug}.#{episode[:format]}"
            path = File.join(@target, 'episodes', audio_file)
            audio_file = nil unless download(enclosure_url, path, label: 'audio')
          else
            warn_about "#{episode[:title]}: skipped enclosure #{episode[:enclosure_url]} - unsupported format " \
                       "(octopod handles #{FORMATS.join('/')})"
          end
        end
        front_matter['audio'] = { episode[:format] => audio_file } if audio_file

        if episode[:image_url] && absolute_url(episode[:image_url], @source) != channel_image
          image = "episodes/#{slug}.#{image_extension(episode[:image_url])}"
          if download(absolute_url(episode[:image_url], @source), File.join(@target, 'assets', 'img', image), label: 'image')
            front_matter['image'] = image
          end
        end

        front_matter['summary'] = episode[:summary] if episode[:summary]
        front_matter['tags'] = episode[:tags].uniq unless episode[:tags].empty?
        chapters = episode[:chapters].empty? ? fetch_json_chapters(episode) : episode[:chapters]
        front_matter['chapters'] = chapters unless chapters.empty?
        front_matter['guid'] = episode[:guid] if episode[:guid]

        # Named after the audio file so PodlovePlayerTag#transcripts_for picks it up on its own.
        # Still downloaded when the audio is only linked (the player parses it at build time),
        # but then named explicitly, since there's no local audio file for it to sit next to.
        if episode[:transcript_url] && audio_file &&
           download(absolute_url(episode[:transcript_url], @source),
                    File.join(@target, 'episodes', "#{slug}.vtt"), label: 'transcript') && @download_url
          front_matter['transcript'] = "#{slug}.vtt"
        end

        post_path = File.join(@target, '_posts', "#{episode[:date].strftime('%Y-%m-%d')}-#{slug}.md")
        File.write(post_path, front_matter.to_yaml + "---\n\n" + post_body(episode[:body], audio_file))
        say "  wrote #{post_path.delete_prefix(@target + '/')}"
        !audio_file.nil?
      end

      # Shownotes go in unchanged, wrapped in {% raw %} so any '{{' or '{%' in them can't break the
      # Liquid pass, and - for HTML - in a single <div> so kramdown passes the whole block through
      # untouched instead of reading indented lines inside it as code blocks.
      def post_body(body, audio_file)
        # Drop the empty mount point a jekyll-octopod feed's own {% podlove_player %} left behind;
        # the imported post gets a fresh player tag instead.
        body = body.gsub(%r{<div id="podlove-player-\w+">\s*</div>}, '').strip
        content = +''
        content << "{% podlove_player %}\n\n" if audio_file
        return content if body.empty?

        body = "<div class=\"shownotes\">\n#{body}\n</div>" if body.match?(/<[a-z][^>]*>/i)
        content << "{% raw %}\n#{body}\n{% endraw %}\n"
      end

      # podcast:chapters points at a JSON chapters file rather than inlining them like psc does.
      def fetch_json_chapters(episode)
        return [] unless episode[:chapters_url]

        # Podlove Publisher links a chapters URL for every episode and answers it with an empty
        # body when an episode has none - that's "no chapters", not an error.
        body = @fetcher.read(absolute_url(episode[:chapters_url], @source))
        return [] if body.strip.empty?

        data = JSON.parse(body)
        (data['chapters'] || []).filter_map do |chapter|
          next nil unless chapter['startTime'] && chapter['title']
          "#{normalize_timestamp(chapter['startTime'].to_f)} #{chapter['title']}"
        end
      rescue StandardError => e
        warn_about "#{episode[:title]}: couldn't read chapters from #{episode[:chapters_url]} (#{e.message})"
        []
      end

      # Slugs come from the last path segment of the episode's old web page where there is one
      # (".../2026/09/08/episode1.html" -> "episode1"), so a migrated site keeps its post and
      # /players/<slug> URLs; from the title otherwise, and for query-string or purely numeric
      # links ("?p=123", ".../episodes/42") that say nothing about the episode.
      # The longest directory URL every supported enclosure lives under, without the trailing
      # slash, for 'download_url'. Episodes spread over several hosts (a podcast that changed
      # hosters, say) can't be expressed as one download_url, so that's an error rather than a
      # silently broken feed.
      def enclosure_base_url(episodes)
        urls = episodes.select { |episode| episode[:enclosure_url] && FORMATS.include?(episode[:format]) }
                       .map { |episode| absolute_url(episode[:enclosure_url], @source) }
        return nil if urls.empty?

        prefix = urls.inject do |common, url|
          length = common.each_char.zip(url.each_char).take_while { |a, b| a == b }.size
          common[0, length]
        end
        prefix = prefix[0..prefix.rindex('/')] if prefix.include?('/')
        unless prefix.match?(%r{\Ahttps?://[^/]+/}i)
          raise ArgumentError, "--no-download needs all enclosures on one host, but they're spread over " \
                               "#{urls.map { |url| URI(url).host }.uniq.join(', ')} - import with downloads instead"
        end
        prefix.chomp('/')
      end

      # The feed's enclosure length, or - where feeds leave it at 0, which happens a lot - the
      # Content-Length of a HEAD request, since the player and feed need a real size.
      def enclosure_size(episode, url)
        return episode[:enclosure_length] if episode[:enclosure_length].to_i > 0

        size = @fetcher.size(url)
        return size if size.to_i > 0
        warn_about "#{episode[:title]}: no file size in the feed or from the server for #{url} - set 'filesize' by hand"
        nil
      rescue StandardError => e
        warn_about "#{episode[:title]}: couldn't get the file size of #{url} (#{e.message}) - set 'filesize' by hand"
        nil
      end

      # Oldest episode first, so when two episodes slugify the same, the earlier one keeps the
      # plain slug and later ones get -2, -3, ...
      def assign_slugs(episodes)
        used = Hash.new(0)
        episodes.each do |episode|
          base = link_slug(episode[:link]) || slugify(episode[:title]) || 'episode'
          used[base] += 1
          episode[:slug] = used[base] == 1 ? base : "#{base}-#{used[base]}"
        end
      end

      # Downloads into a '.part' file that's only renamed once complete, so an existing target
      # file always means a finished earlier download - which is what makes re-running an
      # interrupted import with --force skip everything it already has.
      def download(url, path, label:)
        if File.exist?(path) && File.size(path) > 0
          say "  #{label}: already downloaded, keeping #{path.delete_prefix(@target + '/')}"
          return true
        end

        FileUtils.mkdir_p(File.dirname(path))
        partial = "#{path}.part"
        say "  #{label}: #{url}"
        @fetcher.download(url, partial)
        FileUtils.mv(partial, path)
        true
      rescue StandardError => e
        FileUtils.rm_f(partial) if partial
        warn_about "couldn't download #{label} #{url} (#{e.message})"
        false
      end

      # --- Helpers ----------------------------------------------------------------------------

      def children(node, ns, name)
        return [] unless node
        node.elements.select { |element| element.name == name && NAMESPACES[ns].include?(element.namespace) }
      end

      def child(node, ns, name)
        children(node, ns, name).first
      end

      # Text content of a child element (CDATA included), stripped, or nil if missing/blank.
      def text(node, ns, name)
        element = child(node, ns, name)
        return nil unless element

        value = element.texts.map(&:value).join.strip
        value.empty? ? nil : value
      end

      def split_list(value)
        value.to_s.split(',').map(&:strip).reject(&:empty?)
      end

      def parse_date(value)
        return Time.now unless value
        Time.rfc2822(value)
      rescue ArgumentError
        begin
          Time.parse(value)
        rescue ArgumentError
          Time.now
        end
      end

      def normalize_explicit(value)
        case value.to_s.strip.downcase
        when 'yes', 'true', 'explicit' then 'yes'
        when 'no', 'false' then 'no'
        when 'clean' then 'clean'
        end
      end

      # itunes:duration may be plain seconds, MM:SS or H:MM:SS - always stored as HH:MM:SS.
      def normalize_duration(value)
        return nil unless value && value.match?(/\A\d+(:\d+){0,2}(\.\d+)?\z/)

        seconds = value.split(':').map(&:to_f).inject(0) { |total, part| total * 60 + part }.to_i
        format('%02d:%02d:%02d', seconds / 3600, seconds / 60 % 60, seconds % 60)
      end

      # Chapter starts (psc 'start' attributes, or seconds from JSON chapters) as HH:MM:SS.mmm,
      # the form OctopodFilters#split_chapter and the sample episode use.
      def normalize_timestamp(value)
        seconds = if value.is_a?(Numeric)
                    value.to_f
                  else
                    value.to_s.split(':').map(&:to_f).inject(0) { |total, part| total * 60 + part }
                  end
        millis = (seconds * 1000).round
        format('%02d:%02d:%02d.%03d', millis / 3_600_000, millis / 60_000 % 60, millis / 1000 % 60, millis % 1000)
      end

      def format_for(mime, url)
        mime = mime.to_s.split(';').first.to_s.strip.downcase
        extension = File.extname(URI(url).path).delete('.').downcase rescue ''
        return 'opus' if extension == 'opus'
        FORMATS_BY_MIME[mime] || (FORMATS.include?(extension) ? extension : (extension.empty? ? mime : extension))
      end

      def image_extension(url)
        extension = File.extname(URI(url).path).delete('.').downcase rescue ''
        extension = 'jpg' if extension == 'jpeg'
        IMAGE_EXTENSIONS.include?(extension) ? extension : 'jpg'
      end

      def sniff_image_type(path)
        magic = File.binread(path, 8)
        return 'jpg' if magic.start_with?("\xFF\xD8".b)
        return 'png' if magic.start_with?("\x89PNG".b)
        nil
      end

      def link_slug(link)
        return nil unless link
        slug = slugify(File.basename(URI(link).path.to_s, '.*'))
        slug unless slug.nil? || slug.match?(/\A\d+\z/)
      rescue URI::Error
        nil
      end

      def slugify(value)
        return nil unless value

        slug = value.downcase
                    .gsub('ä', 'ae').gsub('ö', 'oe').gsub('ü', 'ue').gsub('ß', 'ss')
                    .unicode_normalize(:nfkd).gsub(/[^\x00-\x7F]/, '')
                    .gsub(/[^a-z0-9]+/, '-').gsub(/\A-+|-+\z/, '')[0, 60].sub(/-+\z/, '')
        slug.empty? ? nil : slug
      end

      def absolute_url(url, base)
        return url if base.nil? || File.file?(base.to_s)
        URI.join(base, url).to_s
      rescue URI::Error
        url
      end

      def say(*lines)
        lines.each { |line| @out.puts line }
      end

      def warn_about(message)
        @warnings << message
        say "  WARNING: #{message}"
      end

      # Plain Net::HTTP instead of open-uri: podcast hosts routinely bounce enclosures through
      # several tracking redirects (sometimes https -> http, which open-uri refuses), and
      # enclosures are streamed to disk instead of being held in memory.
      class HttpFetcher
        MAX_REDIRECTS = 10
        USER_AGENT = "jekyll-octopod/#{VERSION::STRING} (+https://github.com/jekyll-octopod/jekyll-octopod)"

        def read(url)
          body = request(url) { |response| response.body }
          body.force_encoding(Encoding::UTF_8)
        end

        def size(url)
          request(url, method: Net::HTTP::Head) { |response| response['content-length'].to_i }
        end

        def download(url, path)
          request(url) do |response|
            total = response['content-length'].to_i
            done = 0
            File.open(path, 'wb') do |file|
              response.read_body do |chunk|
                file.write(chunk)
                done += chunk.bytesize
                print "\r    #{done * 100 / total}% of #{total / 1_048_576} MB" if total > 0 && $stdout.tty?
              end
            end
            puts if total > 0 && $stdout.tty?
          end
        end

        private

        def request(url, redirects_left = MAX_REDIRECTS, method: Net::HTTP::Get, &block)
          uri = URI(url)
          raise ArgumentError, "not an http(s) URL: #{url}" unless uri.is_a?(URI::HTTP)

          redirect = nil
          result = nil
          Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https',
                          open_timeout: 30, read_timeout: 300) do |http|
            http.request(method.new(uri.request_uri, 'User-Agent' => USER_AGENT)) do |response|
              case response
              when Net::HTTPRedirection then redirect = URI.join(url, response['location']).to_s
              when Net::HTTPSuccess then result = block.call(response)
              else raise "HTTP #{response.code} #{response.message}"
              end
            end
          end
          return result unless redirect
          raise "too many redirects" if redirects_left.zero?

          request(redirect, redirects_left - 1, method: method, &block)
        end
      end
    end
  end
end
