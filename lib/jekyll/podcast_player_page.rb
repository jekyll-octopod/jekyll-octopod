module Jekyll
  class PodcastPlayerPage < Page
    def initialize(site, base, dir, post)
      @site = site
      @base = base
      @dir  = dir
      @name = 'index.html'

      self.process(@name)
      @path = ThemeLayout.path_for(site, base, 'player_index.html')
      self.read_yaml(base, 'player_index.html')

      self.data['title']    = post.data['title']
      self.data['subtitle'] = post.data['subtitle']
      self.data['datum']    = post.data['datum']
      self.data['date']     = post.date
      self.data['author']   = post.data['author']
      self.data['duration'] = post.data['duration']
      self.data['summary']  = post.data['summary']
      self.data['explicit'] = post.data['explicit']
      self.data['audio']    = post.data['audio']
      self.data['filesize'] = post.data['filesize']
      self.data['chapters'] = post.data['chapters']
      self.data['template'] = 'player_index'
    end
  end
end