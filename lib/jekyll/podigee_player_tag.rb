module Jekyll
  class PodigeePlayerTag < Liquid::Tag
    # From here: https://github.com/podigee/podigee-podcast-player/tree/master/src/themes
    PLAYER_THEMES = ["default", "default-dark", "legacy", "minimal", "republica"]

    def playerconfig(context)
      config = context.registers[:site].config
      page = context.registers[:page]

      audio = {}
      download_url = config["download_url"] || config["url"] + "/episodes"
      page["audio"].each { |key, value| audio[key] = download_url + "/" + value}

      { options: { theme: config["player_theme"] && PLAYER_THEMES.include?(config["player_theme"]) ? config["player_theme"] : "default",
                   startPanel: "ChapterMarks" },
        extensions: { ChapterMarks: {},
                      EpisodeInfo:  {},
                      Playlist:     {} },
        title: options['title'],
        episode: { media: audio,
                   coverUrl: config['url'] + "/img/" + (page["image"] || "logo-360x360.png"),
                   title: page["title"],
                   subtitle: page["subtitle"],
                   url: config['url'] + page["url"],
                   description: page["description"],
                   chaptermarks: page["chapters"] ? page["chapters"].map {|chapter| { start: chapter[0..12], title: chapter[13..255] }} : nil
                 }
      }.to_json
    end

    def render(context)
      config = context.registers[:site].config
      page = context.registers[:page]
      return unless page["audio"]
      return <<~HTML
        <script>
          window.playerConfiguration = #{playerconfig(context)}
        </script>
        <script class="podigee-podcast-player" data-configuration="playerConfiguration"
                src="#{config["url"]}/podigee-player/javascripts/podigee-podcast-player.js">
        </script>
HTML
    end
  end
end

Liquid::Template.register_tag('podigee_player', Jekyll::PodigeePlayerTag)

# src="#{config["url"].split(":").first}://cdn.podigee.com/podcast-player/javascripts/podigee-podcast-player.js">