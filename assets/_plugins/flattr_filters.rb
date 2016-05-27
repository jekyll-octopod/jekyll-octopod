require 'erb'

module Jekyll
  module FlattrFilters

    # Generates the query string part for the flattr load.js from the
    # configurations in _config.yml
    #
    #   {{ site | flattr_loader_options }}
    def flattr_loader_options(site)
      return if site['flattr_uid'].nil?
      keys = %w[mode https popout uid button language category]
      options = flattr_options(site, nil, keys).delete_if { |_, v| v.to_s.empty? }

      options.map { |k, v| "#{k}=#{ERB::Util.url_encode(v)}" }.join('&')
    end

    # Returns a flattr button
    #
    #   {{ site | flattr_button:page }}
    def flattr_button(site, page = nil)
      return if site['flattr_uid'].nil?

      keys = %w[url title description uid popout button category language tags]
      options = flattr_options(site, page, keys)

      button =  '<a class="FlattrButton" style="display:none;" '
      button << %Q{title="#{options.delete('title')}" href="#{options.delete('url')}" }
      button << options.map { |k, v|
        %Q{data-flattr-#{k}="#{v}"} unless k == 'description'
      }.join(' ')
      button << ">\n\n#{options['description'].gsub(/<\/?[^>]*>/, "")}\n</a>"
    end

    # Returns a RSS payment link.
    #
    #   {{ site | flattr_rss:post }}
    def flattr_rss(site, page = nil)
      return if site['flattr_uid'].nil?
      link =  '<atom:link rel="payment" href="https://flattr.com/submit/auto?'
      link << %Q{#{flattr_feed_options(site, page)}" type="text/html" />}
    end

    # Returns a ATOM payment link.
    #
    #   {{ site | flattr_atom:post }}
    def flattr_atom(site, page = nil)
      return if site['flattr_uid'].nil?
      link =  '<link rel="payment" href="https://flattr.com/submit/auto?'
      link << %Q{#{flattr_feed_options(site, page)}" type="text/html" />}
    end

    # Removes all leading "flattr_" from the keys of the given hash.
    #
    #   flattrize({ 'octopod' => 'awesome', 'flattr_uid' => 'pattex' })
    #   => { "octopod" => "awesome", "uid" => "pattex" }
    def flattrize(hsh)
      config = {}
      hsh.to_hash.each { |k, v|
        if new_key = k.to_s.match(/\Aflattr_(.*)\z/)
          config[new_key[1]] = v
        else
          config[k] = v
        end
      }

      config
    end

    def flattr_options(site, page, keys)
      page = {} if page.nil?
      site = flattrize(site)
      page = flattrize(page)
      options = {}

      keys.each { |k|
        case k
        when 'https'
          options[k] = 1
        when 'url'
          options[k] = "#{site['url']}#{page['url']}"
        when 'description'
          options[k] = page['content'] || site['description'] || site['title']
        when 'category'
          options[k] = page['category'] || site['category'] || 'audio'
        when 'language'
          options[k] = page['language'] || site['language'] || 'en_GB'
        when 'tags'
          options[k] = page['tags'].join(', ') if page['tags']
        else
          options[k] = page[k] || site[k]
        end
       }

       options
    end

    def flattr_feed_options(site, page)
      keys = %w[url uid]
      options = flattr_options(site, page, keys).map { |k, v|
        "#{k == 'uid' ? 'user_id' : k}=#{ERB::Util.url_encode(v)}"
      }.join('&amp;')
    end

  end
end

Liquid::Template.register_filter(Jekyll::FlattrFilters)
