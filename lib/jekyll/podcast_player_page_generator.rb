module Jekyll
  class PodcastPlayerPageGenerator < Generator
    safe true

    def generate(site)
      return unless site.layouts.key? 'player_index'

      dir = site.config['players_dir'] || 'players'

      # post.data['slug'] is derived from the filename's title portion only (no date), so two
      # posts can legitimately share one - e.g. a recurring "Update" or "Q&A" episode, or (as
      # found on panoptikum.io) two differently-titled posts that happen to share a filename
      # word. Without disambiguation, both would resolve to the same players/<slug>/ page and
      # one would silently vanish - whichever Jekyll generates second overwrites the first with
      # no warning from this generator itself (Jekyll does warn about the resulting destination
      # conflict, but only after the fact). The earliest post keeps the plain slug path so
      # existing links for the common (non-colliding) case never change; later posts sharing
      # that slug get their date appended instead of being dropped.
      site.posts.docs.group_by { |post| post.data['slug'] }.each_value do |posts_with_slug|
        posts_with_slug.sort_by(&:date).each_with_index do |post, index|
          slug = post.data['slug']
          page_dir = index.zero? ? slug : "#{slug}-#{post.date.strftime('%Y%m%d')}"
          site.pages << PodcastPlayerPage.new(site, site.source, File.join(dir, page_dir), post)
        end
      end
    end
  end
end