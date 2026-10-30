module Jekyll
  class PagedFeedPage < Page
    def initialize(site, base, dir, name, page_number, pages_total, format)
      @site = site
      @dir = "/"
      @name = name

      self.process(@name)
      @path = ThemeLayout.path_for(site, base, 'feed.xml')
      self.read_yaml(base, 'feed.xml')
      self.data['next'] = pages_total > page_number ? (page_number + 1).to_s : nil
      self.data['last'] = pages_total > 1 ? pages_total.to_s : nil
      self.data['prev'] = case page_number
        when 1 then nil
        when 2 then ""
        else        (page_number - 1).to_s
      end
      self.data['myself'] = page_number == 1 ? nil : page_number.to_s
      self.data['format'] = format
      self.data['page_number'] = page_number

      # Full URLs for the feed's self/first/last/next/prev links, so the theme doesn't have to
      # rebuild them from the naming convention (which an 'episode_feed_permalinks' entry changes).
      config = site.config
      self.data['self_url'] = OctopodFilters.feed_url(config, format, page_number)
      self.data['first_url'] = OctopodFilters.feed_url(config, format, 1)
      self.data['last_url'] = OctopodFilters.feed_url(config, format, [pages_total, 1].max)
      self.data['next_url'] = OctopodFilters.feed_url(config, format, page_number + 1) if pages_total > page_number
      self.data['prev_url'] = OctopodFilters.feed_url(config, format, page_number - 1) if page_number > 1

      # Only the canonical first page moves; the generator's duplicate "episodes1.<format>.rss"
      # stays where it is.
      if name == "episodes.#{format}.rss"
        path = OctopodFilters.feed_path(config, format, 1)
        @feed_path = path unless path == "/#{name}"
        self.data['permalink'] = @feed_path if @feed_path
      end
    end

    # A custom feed path ending in "/" (like Podlove's "/feed/mp3/") is written as index.html, the
    # one directory index every web server serves without extra configuration. Jekyll's default
    # would be index.rss, which no server picks up for a directory URL.
    def destination(dest)
      return super unless @feed_path

      path = @feed_path.end_with?('/') ? "#{@feed_path}index.html" : @feed_path
      site.in_dest_dir(dest, URL.unescape_path(path))
    end
  end
end
