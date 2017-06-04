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
    end
  end
end