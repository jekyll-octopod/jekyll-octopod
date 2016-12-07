module Jekyll
  class PodcastPlayerPageGenerator < Generator
    safe true

    def generate(site)
      if site.layouts.key? 'player_index'
        dir =  site.config['players_dir'] || 'players'
        site.posts.docs.each do |post|
          site.pages << PodcastPlayerPage.new(site, site.source, File.join(dir, post.data['slug']), post)
        end
      end
    end
  end
end