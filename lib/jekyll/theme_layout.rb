module Jekyll
  # Resolves the layout file that PagedFeedPage and PodcastPlayerPage read directly (instead of
  # going through a page's normal 'layout:' front matter, which Jekyll::LayoutReader already
  # resolves site-then-theme on its own). Mirrors Jekyll::Layout#initialize's own precedence
  # (see jekyll/layout.rb in the jekyll gem): prefer the site's own '_layouts/', fall back to the
  # active theme's. Needed since jekyll-octopod-bulma (0.18.0+) ships 'feed.xml'/'player_index.html'
  # as theme content instead of every site getting its own copy via 'octopod setup'/'update'.
  module ThemeLayout
    def self.path_for(site, base, filename)
      if File.exist?(File.join(base, '_layouts', filename))
        site.in_source_dir(base, '_layouts', filename)
      elsif site.theme&.layouts_path
        site.in_theme_dir(site.theme.layouts_path, filename)
      else
        site.in_source_dir(base, '_layouts', filename)
      end
    end
  end
end
