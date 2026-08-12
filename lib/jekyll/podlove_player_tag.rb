require 'jekyll/octopod_filters'

module Jekyll
  class PodlovePlayerTag < Liquid::Tag
    include Jekyll::OctopodFilters

    # From here: https://docs.podlove.org/podlove-web-player/v5/configuration
    def playerconfig(context)
      config = context.registers[:site].config
      page = context.registers[:page]

      download_url = download_url_with_fallback(config)
      audio = (page["audio"] || {}).map do |format, filename|
        size = if page["filesize"] && page["filesize"][format]
                 size_by_format(page, format)
               else
                 file_size(filename)
               end
        { url: download_url + "/" + filename,
          size: size,
          mimeType: mime_type(format),
          title: format }
      end

      # Podlove Web Player v5's default theme has no UI element that displays episode.subtitle
      # anywhere (verified: absent from the compact header, the chapters panel, and at every
      # viewport width tested) even though it's correctly present in the player's own Redux
      # state - a gap in their stock theme, not a data problem on our end. Folding subtitle into
      # the title that *is* displayed is the pragmatic workaround; the plain subtitle field is
      # still sent too, in case a future custom theme (or theirs, if they ever fix it) uses it.
      title = page["subtitle"] ? "#{page["title"]} - #{page["subtitle"]}" : page["title"]

      { version: 5,
        title: title,
        subtitle: page["subtitle"],
        summary: page["summary"],
        poster: config['url'] + "/assets/img/" + (page["image"] || "logo-360x360.png"),
        link: config['url'] + page["url"],
        publicationDate: page["date"].respond_to?(:xmlschema) ? page["date"].xmlschema : page["date"].to_s,
        duration: page["duration"],
        audio: audio,
        chapters: page["chapters"] ? page["chapters"].map { |chapter| split_chapter(chapter) }.compact : nil
      }.to_json
    end

    def playerbaseconfig(context)
      config = context.registers[:site].config
      { version: 5, base: "#{config["url"]}/assets/podlove-player/" }.to_json
    end

    def render(context)
      page = context.registers[:page]
      return unless page["audio"]
      config = context.registers[:site].config
      id = "podlove-player-#{page['id'] ? sha1(page['id'], 8) : 'embed'}"
      return <<~HTML
        <div id="#{id}"></div>
        <script src="#{config["url"]}/assets/podlove-player/embed.js"></script>
        <script>
          window.podlovePlayer('##{id}', #{playerconfig(context)}, #{playerbaseconfig(context)});
        </script>
HTML
    end
  end
end

Liquid::Template.register_tag('podlove_player', Jekyll::PodlovePlayerTag)
