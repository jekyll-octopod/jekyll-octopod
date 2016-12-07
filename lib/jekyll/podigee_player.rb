module Jekyll
  module PodigeePlayer

#  <script>
#    window.playerConfiguration = <%= podigee_episodestruct(@episode) %>
#  </script>
#  <script class="podigee-podcast-player"
#    src="https://cdn.podigee.com/podcast-player/javascripts/podigee-podcast-player.js"
#    data-configuration="playerConfiguration">
#  </script>

# def podigee_episodestruct(episode) do
#   %{options: %{theme: "default",
#                startPanel: "ChapterMarks"},
#     extensions: %{ChapterMarks: %{},
#                   EpisodeInfo: %{},
#                   Playlist: %{}},
#     title: episode.podcast.title,
#     episode: %{media: enclosuremap(episode.enclosures),
#                coverUrl: episode.podcast.image_url,
#                title: episode.title,
#                subtitle: episode.subtitle,
#                url: episode.deep_link,
#                description: episode.description,
#                chaptermarks: chapterlist(episode.chapters)
#              }
#   }
#   |> Poison.encode!
#   |> raw
# end


# defp chapterlist(chapters) do
#   Enum.map(chapters, fn(chapter) -> %{start: chapter.start,
#                                       title: chapter.title} end)
# end


# defp enclosuremap(enclosures) do
#   Enum.map(enclosures, fn(enclosure) -> %{filetype(enclosure) => enclosure.url} end)
#   |> List.first
# end

    #   {{ page | podigee_player_script_tag:site }}
    def podigee_player_script_tag(page, site)
      return if page['audio'].nil?

      options = {
        alwaysShowHours: 'true',
        startVolume: '0.8',
        width: 'auto',
        summaryVisible: 'true',
        timecontrolsVisible: 'true',
        chaptersVisible: 'true',
        sharebuttonsVisible: 'true'
      }

      simple_keys = %w[]

      if sitehash = site.posts.first.site.config.dup
        sitehash.delete('title')
        sitehash.delete('subtitle')
        options = options.merge(sitehash)
      end
      options = options.merge(page)

      out = "<script>\n$('audio').podlovewebplayer("
      out << { poster: sitehash['url'] + (options['episode_cover'] || '/img/logo-360x360.png'),
               subtitle: options['subtitle'],
               title: options['title'],
               alwaysShowHours: options['alwaysShowHours'],
               startVolume: options['startVolume'],
               width: options['width'],
               summaryVisible: options['summaryVisible'],
               timecontrolsVisible: options['timecontrolsVisible'],
               chaptersVisible: options['chaptersVisible'],
               sharebuttonsVisible: options['sharebuttonsVisible'],
               show: { title: site['title'],
                       subtitle: site['subtitle'],
                       summary: site['description'],
                       poster: sitehash['url'] + '/img/logo-360x360.png',
                       url: sitehash['url'] },
               chapters: options['chapters'].map {|chapter| split_chapter(chapter)},
               downloads: [
                 { assetTitle: options['title'],
                   size: file_size(page['audio']['mp3']),
                   downloadUrl: sitehash["url"] + "/episodes/" + page['audio']['mp3'] },
               ],
               summary: options['summary'],
               duration: options['duration'],
               permalink: sitehash['url'] + page['url'],
               activeTab: "chapters"
             }.to_json
      out << ")\n</script>"
    end
  end
end

Liquid::Template.register_filter(Jekyll::PodigeePlayer)
