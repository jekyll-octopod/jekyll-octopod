module Jekyll
  module UpdateConfig
    Jekyll::Hooks.register :site, :after_init do |site|
      feeds = Dir["episodes.{???,????}.rss"]
      site.config.update(
        'episode_feed_formats' => feeds.map { |f| f.match(/episodes\.(\w{3,4})\.rss/)[1] }
      )

      # This marker file exists only so the scan above can detect which formats to generate;
      # PagedFeedPageGenerator creates the actual pages at these exact paths. Excluding it here
      # keeps Jekyll's normal reader from also turning it into a page, which would otherwise
      # collide with the generator's output at the same destination.
      # site.exclude (not site.config['exclude']) is what Reader actually consults, and it's
      # copied from config before this hook runs.
      site.exclude += feeds
    end
  end
end