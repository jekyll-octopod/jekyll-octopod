require 'spec_helper'
require 'tmpdir'
require 'stringio'
require 'octopod/importer'

RSpec.describe Jekyll::Octopod::Importer do
  # Serves feed pages and media from memory instead of the network.
  class FakeFetcher
    attr_reader :downloads

    def initialize(responses)
      @responses = responses
      @downloads = []
    end

    def read(url)
      @responses.fetch(url) { raise "HTTP 404 Not Found" }
    end

    def size(url)
      read(url).bytesize
    end

    def download(url, path)
      @downloads << url
      File.binwrite(path, read(url))
    end
  end

  let(:page1) do
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0" xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd"
           xmlns:content="http://purl.org/rss/1.0/modules/content/" xmlns:atom="http://www.w3.org/2005/Atom"
           xmlns:psc="http://podlove.org/simple-chapters" xmlns:podcast="https://podcastindex.org/namespace/1.0">
        <channel>
          <title>Grüße aus Wien</title>
          <atom:link href="https://example.com/feed2.rss" rel="next"/>
          <description>A podcast.</description>
          <language>de-AT</language>
          <copyright>All rights reserved</copyright>
          <itunes:subtitle>The subtitle</itunes:subtitle>
          <itunes:author>Jane Doe</itunes:author>
          <itunes:owner><itunes:name>Jane</itunes:name><itunes:email>jane@example.com</itunes:email></itunes:owner>
          <itunes:explicit>false</itunes:explicit>
          <itunes:keywords>one, two</itunes:keywords>
          <itunes:category text="Society &amp; Culture"><itunes:category text="Places &amp; Travel"/></itunes:category>
          <itunes:image href="https://example.com/logo.png"/>
          <item>
            <title>Episode 2 - Second one</title>
            <itunes:subtitle>Second one</itunes:subtitle>
            <pubDate>Tue, 08 Sep 2026 10:00:00 +0200</pubDate>
            <guid isPermaLink="false">ep2</guid>
            <itunes:duration>3725</itunes:duration>
            <itunes:image href="https://example.com/ep2.jpg"/>
            <description><![CDATA[<div id="podlove-player-2f749899"></div>
      <p>Shownotes with {{ liquid }}</p>

          <p>indented</p>]]></description>
            <enclosure url="https://cdn.example.com/track?id=2" length="5" type="audio/mpeg"/>
            <podcast:transcript url="https://example.com/ep2.vtt" type="text/vtt"/>
            <psc:chapters version="1.1"><psc:chapter start="0:01:02" title="Intro"/></psc:chapters>
          </item>
        </channel>
      </rss>
    XML
  end

  let(:page2) do
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0" xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd">
        <channel>
          <title>ignored</title>
          <item>
            <title>Episode 1</title>
            <link>https://example.com/2026/09/07/first-episode.html</link>
            <pubDate>Mon, 07 Sep 2026 10:00:00 +0200</pubDate>
            <itunes:image href="https://example.com/logo.png"/>
            <description>Plain text notes</description>
            <enclosure url="https://example.com/ep1.m4a" length="4" type="audio/x-m4a"/>
          </item>
          <item>
            <title>Video</title>
            <link>https://example.com/?p=17</link>
            <pubDate>Sun, 06 Sep 2026 10:00:00 +0200</pubDate>
            <enclosure url="https://example.com/ep0.mp4" length="4" type="video/mp4"/>
          </item>
        </channel>
      </rss>
    XML
  end

  let(:fetcher) do
    FakeFetcher.new(
      'https://example.com/feed.rss' => page1, 'https://example.com/feed2.rss' => page2,
      'https://cdn.example.com/track?id=2' => 'audio', 'https://example.com/ep1.m4a' => 'm4a!',
      'https://example.com/logo.png' => "\x89PNG....", 'https://example.com/ep2.jpg' => 'jpeg',
      'https://example.com/ep2.vtt' => "WEBVTT\n"
    )
  end

  around do |example|
    Dir.mktmpdir { |dir| @dir = dir; example.run }
  end

  def import(**options)
    described_class.new('https://example.com/feed.rss', File.join(@dir, 'site'),
                        fetcher: fetcher, out: StringIO.new, **options).run
  end

  def site(path)
    File.join(@dir, 'site', path)
  end

  def front_matter(path)
    YAML.safe_load(File.read(site(path)).split(/^---\s*$/)[1], permitted_classes: [])
  end

  it 'creates one post per episode across all feed pages, oldest first' do
    import
    posts = Dir.children(site('_posts')).sort
    expect(posts).to eq(%w[2026-09-06-video.md 2026-09-07-first-episode.md 2026-09-08-episode-2.md])
  end

  it 'keeps the old page slug from <link> where it says something about the episode' do
    import
    expect(Dir.children(site('_posts'))).to include('2026-09-07-first-episode.md', '2026-09-06-video.md')
  end

  it 'stores enclosures locally and links them by format' do
    import
    episode2 = front_matter('_posts/2026-09-08-episode-2.md')
    expect(episode2).to include('title' => 'Episode 2', 'subtitle' => 'Second one', 'audio' => { 'mp3' => 'episode-2.mp3' },
                                'duration' => '01:02:05', 'chapters' => ['00:01:02.000 Intro'], 'guid' => 'ep2',
                                'image' => 'episodes/episode-2.jpg', 'date' => '2026-09-08 10:00:00 +0200')
    expect(File.read(site('episodes/episode-2.mp3'))).to eq('audio')
    expect(File.read(site('episodes/episode-2.vtt'))).to eq("WEBVTT\n")
    expect(File.read(site('assets/img/episodes/episode-2.jpg'))).to eq('jpeg')
    expect(front_matter('_posts/2026-09-07-first-episode.md')['audio']).to eq('m4a' => 'first-episode.m4a')
    expect(File.read(site('episodes/first-episode.m4a'))).to eq('m4a!')
  end

  it 'skips unsupported enclosures and channel-image duplicates, with a warning' do
    importer = import
    video = front_matter('_posts/2026-09-06-video.md')
    expect(video).not_to have_key('audio')
    expect(importer.warnings.join).to include('ep0.mp4')
    expect(front_matter('_posts/2026-09-07-first-episode.md')).not_to have_key('image')
    expect(fetcher.downloads).not_to include('https://example.com/ep0.mp4')
  end

  it 'protects shownotes from Liquid and kramdown, and adds the player tag' do
    import
    body = File.read(site('_posts/2026-09-08-episode-2.md')).split(/^---\s*$/, 3)[2]
    expect(body).to start_with("\n{% podlove_player %}\n\n{% raw %}\n<div class=\"shownotes\">\n<p>Shownotes")
    expect(body).not_to include('podlove-player-2f749899')
    expect(body).to end_with("</div>\n{% endraw %}\n")
    expect(File.read(site('_posts/2026-09-07-first-episode.md'))).to include("{% raw %}\nPlain text notes\n{% endraw %}")
    expect(File.read(site('_posts/2026-09-06-video.md'))).not_to include('podlove_player')
  end

  it 'writes feed markers only for formats present' do
    import
    expect(Dir.glob(site('episodes.*.rss')).map { |f| File.basename(f) }.sort).to eq(%w[episodes.m4a.rss episodes.mp3.rss])
    expect(File.exist?(site('_posts/2016-03-22-episode0.md'))).to be false
    expect(File.exist?(site('episodes/episode0.mp3'))).to be false
    expect(File.exist?(site('index.md'))).to be true
  end

  it 'fills _config.yml from the channel, keeping the sample comments' do
    import(site_url: 'https://podcast.example.com')
    raw = File.read(site('_config.yml'))
    config = YAML.safe_load(raw)
    expect(config).to include('title' => 'Grüße aus Wien', 'url' => 'https://podcast.example.com', 'subtitle' => 'The subtitle',
                              'author' => 'Jane Doe', 'email' => 'jane@example.com', 'keywords' => %w[one two],
                              'itunes_categories' => ['Society & Culture'], 'language' => 'de', 'explicit' => 'no',
                              'license' => 'All rights reserved', 'theme' => 'jekyll-octopod-bulma')
    expect(config).not_to include('license_url', 'license_image_url', 'itunes_url', 'fediverse_url')
    expect(raw).to include('### Rsync Deploy config')
  end

  it 'prefers podcast:license, with its link, over <copyright>' do
    page1.sub!('<copyright>', '<podcast:license url="https://creativecommons.org/licenses/by-nc/4.0">cc-by-nc-4.0</podcast:license><copyright>')
    import
    config = YAML.safe_load(File.read(site('_config.yml')))
    expect(config).to include('license' => 'cc-by-nc-4.0', 'license_url' => 'https://creativecommons.org/licenses/by-nc/4.0')
    expect(config).not_to include('license_image_url')
  end

  it 'defaults the target directory to the slugged podcast title' do
    Dir.chdir(@dir) do
      importer = described_class.new('https://example.com/feed.rss', fetcher: fetcher, out: StringIO.new).run
      expect(importer.target).to eq(File.join(Dir.pwd, 'gruesse-aus-wien'))
    end
  end

  it 'honours --limit by keeping the newest episodes' do
    import(limit: 1)
    expect(Dir.children(site('_posts'))).to eq(%w[2026-09-08-episode-2.md])
  end

  context 'with download_enclosures: false' do
    let(:linked_feed) do
      <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0" xmlns:podcast="https://podcastindex.org/namespace/1.0">
          <channel>
            <title>Linked</title>
            <item>
              <title>One</title>
              <pubDate>Mon, 07 Sep 2026 10:00:00 +0200</pubDate>
              <enclosure url="https://media.example.com/audio/2026/one.mp3" length="0" type="audio/mpeg"/>
              <podcast:transcript url="https://example.com/one.vtt" type="text/vtt"/>
            </item>
            <item>
              <title>Two</title>
              <pubDate>Tue, 08 Sep 2026 10:00:00 +0200</pubDate>
              <enclosure url="https://media.example.com/audio/two.mp3?source=feed" length="1234" type="audio/mpeg"/>
            </item>
          </channel>
        </rss>
      XML
    end

    let(:fetcher) do
      FakeFetcher.new('https://example.com/linked.rss' => linked_feed, 'https://example.com/one.vtt' => "WEBVTT\n",
                      'https://media.example.com/audio/2026/one.mp3' => 'x' * 42)
    end

    def import_linked
      described_class.new('https://example.com/linked.rss', File.join(@dir, 'site'), fetcher: fetcher,
                          out: StringIO.new, download_enclosures: false).run
    end

    it 'links enclosures via download_url and filesize instead of downloading them' do
      import_linked
      expect(YAML.safe_load(File.read(site('_config.yml')))['download_url']).to eq('https://media.example.com/audio')
      expect(front_matter('_posts/2026-09-08-two.md')).to include('audio' => { 'mp3' => 'two.mp3?source=feed' },
                                                                  'filesize' => { 'mp3' => 1234 })
      expect(Dir.children(site('episodes'))).to eq(%w[one.vtt])
      expect(fetcher.downloads).to eq(%w[https://example.com/one.vtt])
      expect(File.read(site('_posts/2026-09-08-two.md'))).to include('{% podlove_player %}')
      expect(File.exist?(site('episodes.mp3.rss'))).to be true
    end

    it 'asks the server for the size when the feed has none, and names the transcript explicitly' do
      import_linked
      expect(front_matter('_posts/2026-09-07-one.md')).to include('audio' => { 'mp3' => '2026/one.mp3' },
                                                                  'filesize' => { 'mp3' => 42 },
                                                                  'transcript' => 'one.vtt')
    end

    it 'refuses enclosures spread over several hosts' do
      expect {
        described_class.new('https://example.com/feed.rss', File.join(@dir, 'site'), fetcher: fetcher_for_mixed_hosts,
                            out: StringIO.new, download_enclosures: false).run
      }.to raise_error(ArgumentError, /example\.com, cdn\.example\.com/)
      expect(Dir.exist?(site('.'))).to be false
    end

    def fetcher_for_mixed_hosts
      FakeFetcher.new('https://example.com/feed.rss' => page1, 'https://example.com/feed2.rss' => page2)
    end
  end

  it 'refuses a non-empty target without force, and resumes with it' do
    import
    expect { import }.to raise_error(ArgumentError, /not empty/)
    fetcher.downloads.clear
    import(force: true)
    expect(fetcher.downloads).to be_empty
  end
end
