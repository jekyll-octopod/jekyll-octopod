module Jekyll
  class StaticFile

    def octopod_exclude
      src = path.sub("#{@base}/", '')
      nested_files = %w[img/bigplay.psd readme.txt
        screenshot-1.png screenshot-2.png settings.php standalone.html
        libs/mediaelement/README.md]
      exclude_dirs = %w[]

      excludes = %w[ChangeLog Gemfile Gemfile.lock README.md octopod]
      return true if excludes.include?(src) || exclude_dirs.include?(File.dirname(src))
    end

    alias_method :_octopod_original_write, :write

    def write(dest)
      return true if octopod_exclude

      _octopod_original_write(dest)
    end
  end
end