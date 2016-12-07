module Jekyll
  class StaticFile

    def octopod_exclude
      src = path.sub("#{@base}/", '')
      nested_files = %w[img/bigplay.psd podlove-web-player.php readme.txt
        screenshot-1.png screenshot-2.png settings.php standalone.html
        libs/mediaelement/README.md]
      exclude_dirs = %w[
        podlove-web-player/podlove-web-player/samples
        podlove-web-player/podlove-web-player/libs/mediaelement/demo
        podlove-web-player/podlove-web-player/libs/mediaelement/media
      ]

      excludes = %w[ChangeLog Gemfile Gemfile.lock README.md octopod podlove-web-player/readme.md]
      excludes.concat(nested_files.map { |f| File.join('podlove-web-player/podlove-web-player', f) })

      return true if excludes.include?(src) || exclude_dirs.include?(File.dirname(src))
    end

    alias_method :_octopod_original_write, :write

    def write(dest)
      return true if octopod_exclude

      _octopod_original_write(dest)
    end

  end
end
