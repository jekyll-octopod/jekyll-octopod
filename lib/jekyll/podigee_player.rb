module Jekyll
  module PodigeePlayer

  def podigee_player_stript(site, page) do
    return if page['audio'].nil?
    output = <<xxx
      <script>
        window.playerConfiguration = %{podigee_episodehash(site, page, page['episode']}
      </script>
      <script class="podigee-podcast-player"
              src="https://cdn.podigee.com/podcast-player/javascripts/podigee-podcast-player.js"
              data-configuration="playerConfiguration">
      </script>
xxx
  end

  def podigee_episodehash(site, page, episode) do
    {options: {theme: "default",
               startPanel: "ChapterMarks"},
     extensions: {ChapterMarks: {},
                  EpisodeInfo: {},
		  Playlist: {}},
     title: options['title'],
     episode: { media: "mp3": sitehash["url"] + "/episodes/" + page['audio']['mp3']},
                coverUrl: sitehash['url'] + (options['episode_cover'] || '/img/logo-360x360.png',
                title: options['title'],
                subtitle: options['subtitle'],
                url: sitehash['url'] + page['url'],
                description: episode.description,
                chaptermarks: options['chapters'].map {|chapter| {start: chapter.start, title: chapter.title})
              }
    }.to_json
  end

Liquid::Template.register_filter(Jekyll::PodigeePlayer)
