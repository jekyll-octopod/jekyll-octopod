module Jekyll
  module UpdateConfig
    Jekyll::Hooks.register :site, :after_init do |site|
      feeds = Dir["episodes.{???,????}.rss"]
      site.config.update(
        'episode_feed_formats' => feeds.map { |f| f.match(/episodes\.(\w{3,4})\.rss/)[1] }
      )
      jsonfeeds = Dir["feed.{???,????}.json"]
      site.config.update(
        'json_feed_formats'    => jsonfeeds.map { |f| f.match(/feed\.(\w{3,4})\.json/)[1] }
      )

      # These marker files exist only so the scan above can detect which
      # formats to generate; PagedFeedPageGenerator creates the actual pages
      # at these exact paths. Excluding them here keeps Jekyll's normal
      # reader from also turning them into pages, which would otherwise
      # collide with the generator's output at the same destination.
      # site.exclude (not site.config['exclude']) is what Reader actually
      # consults, and it's copied from config before this hook runs.
      site.exclude += feeds + jsonfeeds
    end
  end
end