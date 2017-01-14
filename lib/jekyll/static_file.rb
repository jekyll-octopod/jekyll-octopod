module Jekyll
  class StaticFile

    def octopod_exclude
      src = path.sub("#{@base}/", '')
      nested_files = %w[]

      excludes = %w[Gemfile Gemfile.lock README.md octopod]
      return true if excludes.include?(src)
    end

    alias_method :_octopod_original_write, :write

    def write(dest)
      return true if octopod_exclude

      _octopod_original_write(dest)
    end
  end
end