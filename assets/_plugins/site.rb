module Jekyll
  class Site

    alias_method :_octopod_original_process, :process

    def process
      feeds = Dir["episodes.{???,????}.rss"]
      config.update(
        'episode_feed_formats' => feeds.map { |f| f.match(/episodes\.(\w{3,4})\.rss/)[1] }
      )

      _octopod_original_process
    end

  end
end
