require "spec_helper"
require "liquid"
require "jekyll/octopod_filters"

describe "episode feed URLs" do
  let(:site) { { "url" => "https://example.com", "episode_feed_formats" => %w[mp3 m4a] } }

  describe "Jekyll::OctopodFilters.feed_path" do
    it "follows the episodes.<format>.rss naming convention by default" do
      expect(Jekyll::OctopodFilters.feed_path(site, "mp3")).to eq("/episodes.mp3.rss")
      expect(Jekyll::OctopodFilters.feed_path(site, "mp3", 3)).to eq("/episodes3.mp3.rss")
    end

    it "moves only the first page of a format with an episode_feed_permalinks entry" do
      site["episode_feed_permalinks"] = { "mp3" => "/feed/mp3/" }

      expect(Jekyll::OctopodFilters.feed_path(site, "mp3")).to eq("/feed/mp3/")
      expect(Jekyll::OctopodFilters.feed_path(site, "mp3", 2)).to eq("/episodes2.mp3.rss")
      expect(Jekyll::OctopodFilters.feed_path(site, "m4a")).to eq("/episodes.m4a.rss")
    end

    it "adds a missing leading slash and ignores empty entries" do
      site["episode_feed_permalinks"] = { "mp3" => "feed/mp3/", "m4a" => "" }

      expect(Jekyll::OctopodFilters.feed_path(site, "mp3")).to eq("/feed/mp3/")
      expect(Jekyll::OctopodFilters.feed_path(site, "m4a")).to eq("/episodes.m4a.rss")
    end
  end

  describe "#episode_feeds" do
    subject { Object.new.extend(Jekyll::OctopodFilters) }

    it "links to the permalink where one is set" do
      site["episode_feed_permalinks"] = { "mp3" => "/feed/mp3/" }

      expect(subject.episode_feeds(site)).to eq([
        ["mp3 Episode RSS-Feed", "https://example.com/feed/mp3/"],
        ["m4a Episode RSS-Feed", "https://example.com/episodes.m4a.rss"]
      ])
    end
  end
end
