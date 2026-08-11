##
# The MIT License (MIT)
#
# Copyright (c) 2014 Ryan Morrissey
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
#
# Line Awesome Icons Liquid Tag
# Documentation can be found at https://icons8.com/line-awesome
#
# Line Awesome ships three icon families sharing one glyph namespace: 'las' (solid, the
# default here), 'lar' (regular/outline) and 'lab' (brands - Twitter, Facebook, Apple, etc.,
# who only exist in this family). Because all three families' CSS rules carry equal
# specificity, whichever one is declared last in the compiled stylesheet always wins if more
# than one is present on the same element - so brand icons render nothing under the default
# 'las' class, and must explicitly switch families rather than add 'lab' alongside it.
#
# Example:
#    {% icon la-camera-retro %}
#    {% icon la-camera-retro la-lg %}
#    {% icon la-spinner la-spin %}
#    {% icon la-shield la-rotate-90 %}
#    {% icon la-twitter lab %}     # brand icon: replaces the family, doesn't just add a class
#    {% icon la-star lar %}        # outline/regular style instead of the default solid

module Jekyll
  class LineAwesomeTag < Liquid::Tag

    ICON_FAMILIES = %w[las lar lab].freeze

    def render(context)
      if tag_contents = determine_arguments(@markup.strip)
        icon_class, icon_extra = tag_contents[0], tag_contents[1]
        icon_tag(icon_class, icon_extra)
      else
        raise ArgumentError.new <<-eos
Syntax error in tag 'icon' while parsing the following markup:

  #{@markup}

Valid syntax:
  for icons: {% icon la-camera-retro %}
  for icons with size/spin/rotate: {% icon la-camera-retro la-lg %}
  for a non-default family (lar/lab): {% icon la-twitter lab %}
eos
      end
    end

    private

    def determine_arguments(input)
      matched = input.match(/\A(\S+) ?(\S+)?\Z/)
      [matched[1].to_s.strip, matched[2].to_s.strip] if matched && matched.length >= 3
    end

    def icon_tag(icon_class, icon_extra = nil)
      family = ICON_FAMILIES.include?(icon_extra) ? icon_extra : 'las'
      modifier = ICON_FAMILIES.include?(icon_extra) ? nil : icon_extra

      if modifier.nil? || modifier.empty?
        "<i class=\"#{family} #{icon_class}\"></i>"
      else
        "<i class=\"#{family} #{icon_class} #{modifier}\"></i>"
      end
    end
  end
end

Liquid::Template.register_tag('icon', Jekyll::LineAwesomeTag)
