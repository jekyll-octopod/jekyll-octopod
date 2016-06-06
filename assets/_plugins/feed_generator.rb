module Jekyll
  class PagedFeedPage < Page
    def initialize(site, base, dir, name, page_number, pages_total, format)
      @site = site
      @dir = "/"
      @name = name

      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), 'feed.xml')
      self.data['next'] = pages_total > page_number ? (page_number + 1).to_s : nil
      self.data['last'] = pages_total > 1 ? pages_total.to_s : nil
      self.data['prev'] = case page_number
        when 1 then nil
        when 2 then ""
        else        (page_number - 1).to_s
      end
      self.data['myself'] = page_number == 1 ? nil : page_number.to_s
      self.data['format'] = format
      self.data['page_number'] = page_number
    end
  end

  class PagedFeedPageGenerator < Generator
    safe true

    def generate(site)
      pages_total = (site.posts.docs.count.to_f / site.config["episodes_per_feed_page"]).ceil

      site.config["episode_feed_formats"].each do |page_format|
        name = "episodes." + page_format + ".rss"
        page = PagedFeedPage.new(site, site.source, ".", name, 1, pages_total, page_format)
        site.pages << page
        (1..pages_total).each do |page_number|
          name = "episodes" + page_number.to_s + "." + page_format + ".rss"
          page = PagedFeedPage.new(site, site.source, ".", name, page_number, pages_total, page_format)
          site.pages << page
        end
      end
    end
  end
end
