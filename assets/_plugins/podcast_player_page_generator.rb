module Jekyll
  class PodcastPlayerPage < Page
    def initialize(site, base, dir, post)
      @site = site
      @base = base
      @dir  = dir
      @name = 'index.html'

      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), 'player_index.html')

      self.data['title']    = post.data['title']
      self.data['subtitle'] = post.data['subtitle']
      self.data['datum']    = post.data['datum']
      self.data['author']   = post.data['author']
      self.data['explicit'] = post.data['explicit']
      self.data['audio']    = post.data['audio']
      self.data['chapters'] = post.data['chapters']
      self.data['template'] = 'player_index'
    end
  end

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