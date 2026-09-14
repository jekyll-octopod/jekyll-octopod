require 'jekyll/octopod_filters'

module Jekyll
  class PodlovePlayerTag < Liquid::Tag
    include Jekyll::OctopodFilters

    # Every channel the player itself supports (per the config docs below) - sent unconditionally
    # rather than exposed as a site/post setting, so the share tab always has something to offer
    # instead of defaulting to the player's own empty channel list.
    SHARE_CHANNELS = %w[twitter facebook whats-app linkedin pinterest xing mail link].freeze

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
        chapters: page["chapters"] ? page["chapters"].map { |chapter| split_chapter(chapter) }.compact : nil,
        transcripts: transcripts_for(page),
        share: { channels: SHARE_CHANNELS }
      }.to_json
    end

    # Finds a WebVTT transcript for this episode and parses it into the cue list Podlove Web
    # Player's "transcripts" config field expects (see the same docs link above the config
    # method: a plain list of { start, start_ms, end, end_ms, speaker, voice, text } cues - the
    # player has no native understanding of WebVTT itself, so this is doing that conversion, not
    # just passing the file through). Looks for an explicit page["transcript"] filename first,
    # then falls back to the audio file's own basename with a .vtt extension (i.e.
    # "episode1.mp3" -> "episode1.vtt"), resolved on disk the same way file_size() locates audio
    # files: relative to the site root if the filename already contains a "/", otherwise under
    # episodes/. Returns nil if there's no matching, parseable file, so the config field is
    # simply omitted rather than sent empty.
    def transcripts_for(page)
      filename = page["transcript"] || vtt_sibling_of(page["audio"])
      return nil unless filename

      path = filename =~ /\// ? filename : File.join('episodes', filename)
      return nil unless File.exist?(path)

      cues = parse_vtt(File.read(path, encoding: 'UTF-8'))
      cues.empty? ? nil : cues
    end

    def vtt_sibling_of(audio_hash)
      return nil unless audio_hash
      primary = audio(audio_hash)
      return nil unless primary

      primary.sub(/\.[^.\/]+\z/, '.vtt')
    end

    # Parses WebVTT cues, including Auphonic's "<v Speaker>text</v>" voice-tag convention. Not a
    # full WebVTT implementation (no styling, regions, or nested tags) - just enough to turn
    # timed, optionally speaker-tagged captions into Podlove's transcript-cue shape.
    def parse_vtt(content)
      content = content.sub(/\A\xEF\xBB\xBF/, '').gsub("\r\n", "\n")

      content.split(/\n\n+/).filter_map do |block|
        lines = block.strip.split("\n")
        next nil if lines.empty?

        # Discard the "WEBVTT" header, NOTE/STYLE/REGION blocks, and any cue identifier line -
        # everything up to the "start --> end" timing line, which is left in place once found.
        lines.shift while lines.first && !lines.first.include?('-->')
        timing = lines.shift
        next nil unless timing

        match = timing.match(/((?:\d{2}:)?\d{2}:\d{2}\.\d{3})\s*-->\s*((?:\d{2}:)?\d{2}:\d{2}\.\d{3})/)
        next nil unless match

        text = lines.join(' ').strip
        voice = text[/\A<v\s+([^>]+)>/, 1]
        text = text.sub(/\A<v\s+[^>]+>/, '').sub(%r{</v>\z}, '').strip

        { start: match[1], start_ms: ms_from_vtt_timestamp(match[1]),
          end: match[2], end_ms: ms_from_vtt_timestamp(match[2]),
          speaker: nil, voice: voice, text: text }
      end
    end

    def ms_from_vtt_timestamp(timestamp)
      parts = timestamp.split(':')
      seconds, millis = parts.pop.split('.')
      minutes = parts.pop.to_i
      hours = parts.empty? ? 0 : parts.pop.to_i

      (((hours * 60) + minutes) * 60 + seconds.to_i) * 1000 + millis.to_i
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
