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
end