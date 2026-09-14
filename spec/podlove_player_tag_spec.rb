require "spec_helper"
require "liquid"
require "jekyll/podlove_player_tag"
require "tmpdir"
require "json"

describe Jekyll::PodlovePlayerTag do
  # Liquid::Tag.new is private in the installed liquid version (tags are meant to be built via
  # Liquid::Tag.parse); allocate sidesteps that, which is fine here since none of the methods
  # under test touch anything Liquid::Tag#initialize would have set up.
  subject { described_class.allocate }

  describe "#parse_vtt" do
    it "parses timed, speaker-tagged cues into Podlove's transcript-cue shape" do
      vtt = <<~VTT
        WEBVTT

        00:00:02.135 --> 00:00:09.557
        <v Stefan>Hallo zusammen, hier die erste Episode.

        00:00:09.557 --> 00:00:12.265
        <v Markus>Und von meiner Seite auch hallo.
      VTT

      expect(subject.parse_vtt(vtt)).to eq([
        { start: "00:00:02.135", start_ms: 2135, end: "00:00:09.557", end_ms: 9557,
          speaker: nil, voice: "Stefan", text: "Hallo zusammen, hier die erste Episode." },
        { start: "00:00:09.557", start_ms: 9557, end: "00:00:12.265", end_ms: 12265,
          speaker: nil, voice: "Markus", text: "Und von meiner Seite auch hallo." }
      ])
    end

    it "skips NOTE blocks and cue identifier lines" do
      vtt = <<~VTT
        WEBVTT

        NOTE
        This is a comment, not a cue.

        1
        00:00:00.000 --> 00:00:01.000
        Cue with a leading identifier line.
      VTT

      cues = subject.parse_vtt(vtt)
      expect(cues.size).to eq(1)
      expect(cues.first[:text]).to eq("Cue with a leading identifier line.")
    end

    it "leaves voice nil for cues without a <v> tag" do
      vtt = <<~VTT
        WEBVTT

        00:00:00.000 --> 00:00:01.000
        Plain cue, no speaker tag.
      VTT

      expect(subject.parse_vtt(vtt).first).to include(voice: nil, text: "Plain cue, no speaker tag.")
    end

    it "joins multi-line cue text with a space" do
      vtt = <<~VTT
        WEBVTT

        00:00:00.000 --> 00:00:01.000
        <v Stefan>First line
        second line.
      VTT

      expect(subject.parse_vtt(vtt).first[:text]).to eq("First line second line.")
    end

    it "returns an empty list for a file with no cues" do
      expect(subject.parse_vtt("WEBVTT\n")).to eq([])
    end
  end

  describe "#ms_from_vtt_timestamp" do
    it "converts HH:MM:SS.mmm timestamps" do
      expect(subject.ms_from_vtt_timestamp("00:01:02.500")).to eq(62_500)
      expect(subject.ms_from_vtt_timestamp("01:00:00.000")).to eq(3_600_000)
    end

    it "converts MM:SS.mmm timestamps without an hours component" do
      expect(subject.ms_from_vtt_timestamp("01:02.500")).to eq(62_500)
    end
  end

  describe "#vtt_sibling_of" do
    it "swaps the primary audio file's extension for .vtt" do
      expect(subject.vtt_sibling_of({ "mp3" => "episode1.mp3", "ogg" => "episode1.ogg" }))
        .to eq("episode1.vtt")
    end

    it "returns nil when there's no audio" do
      expect(subject.vtt_sibling_of(nil)).to be_nil
      expect(subject.vtt_sibling_of({})).to be_nil
    end
  end

  describe "#playerconfig" do
    it "always sends the player's full list of supported share channels" do
      site = double(config: { "url" => "https://example.com" })
      page = { "title" => "Episode 1", "url" => "/episode1.html", "date" => Time.now, "audio" => nil }
      context = double(registers: { site: site, page: page })

      cfg = JSON.parse(subject.playerconfig(context))
      expect(cfg["share"]).to eq({ "channels" => described_class::SHARE_CHANNELS })
    end
  end

  describe "#transcripts_for" do
    around do |example|
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) { example.run }
      end
    end

    it "returns nil when there's no audio and no explicit transcript" do
      expect(subject.transcripts_for({})).to be_nil
    end

    it "returns nil when the auto-detected sibling file doesn't exist on disk" do
      expect(subject.transcripts_for({ "audio" => { "mp3" => "episode1.mp3" } })).to be_nil
    end

    it "auto-detects and parses a .vtt file sitting next to the audio in episodes/" do
      FileUtils.mkdir_p("episodes")
      File.write("episodes/episode1.vtt", "WEBVTT\n\n00:00:00.000 --> 00:00:01.000\n<v Stefan>Hi.\n")

      cues = subject.transcripts_for({ "audio" => { "mp3" => "episode1.mp3" } })
      expect(cues).to eq([
        { start: "00:00:00.000", start_ms: 0, end: "00:00:01.000", end_ms: 1000,
          speaker: nil, voice: "Stefan", text: "Hi." }
      ])
    end

    it "prefers an explicit page['transcript'] filename over auto-detection" do
      FileUtils.mkdir_p("episodes")
      File.write("episodes/custom.vtt", "WEBVTT\n\n00:00:00.000 --> 00:00:01.000\n<v Stefan>Hi.\n")

      cues = subject.transcripts_for({ "audio" => { "mp3" => "episode1.mp3" }, "transcript" => "custom.vtt" })
      expect(cues).not_to be_nil
    end
  end
end
