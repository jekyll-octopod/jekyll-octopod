class Kramdown::Parser::NoopenerGFM < Kramdown::Parser::GFM
  SAFE_OPTS = { "target" => "_blank", "rel"=>"nofollow noopener noreferrer" }.freeze

  def initialize(source, options)
    super
    @same_tab_domains = options.fetch(:same_tab_domains, [])
  end

  def update_elements(element)
    if element.type == :a && \
       element.attr.respond_to?(:[]) && \
       (href = element.attr['href']) && \
       URI::DEFAULT_PARSER.regexp[:ABS_URI].match(href) && \
       !@same_tab_domains.include?(URI::parse(href).host)

      element.attr.merge!(SAFE_OPTS)
    end
    super
  end
end
