# encoding: utf-8
require 'date'

# gem install facets
require 'facets/integer/ordinal'

module Jekyll
  module DateDe
    #Deutsche Lokalisation:
    MONTHNAMES_DE = [nil,
      "Januar", "Februar", "März", "April", "Mai", "Juni",
      "Juli", "August", "September", "Oktober", "November", "Dezember" ]
    ABBR_MONTHNAMES_DE = [nil,
      "Jan", "Feb", "Mär", "Apr", "Mai", "Jun",
      "Jul", "Aug", "Sep", "Okt", "Nov", "Dez" ]
    DAYNAMES_DE = [
      "Sonntag", "Montag", "Dienstag", "Mittwoch",
      "Donnerstag", "Freitag", "Samstag" ]
    ABBR_DAYNAMES_DE = [
      "So", "Mo", "Di", "Mi",
      "Do", "Fr", "Sa" ]

    # Returns a datetime if the input is a string
    def datetime(date)
      if date.class == String
        date = Time.parse(date)
      end
      date
    end

    # Formats date by given date format
    def format_date(date, format)
      date = datetime(date)
        if format.nil? || format.empty? || format == "ordinal"
          date_formatted = ordinalize(date)
        else
          format.gsub!(/%a/, ABBR_DAYNAMES_DE[date.wday])
          format.gsub!(/%A/, DAYNAMES_DE[date.wday])
          format.gsub!(/%b/, ABBR_MONTHNAMES_DE[date.mon])
          format.gsub!(/%B/, MONTHNAMES_DE[date.mon])
          date_formatted = date.strftime(format)
        end
        date_formatted
    end

    # Usage: {{ post.date | full_date_de }}
    # Result: 13. Dezember 2017
    def full_date_de(date)
      format_date(date, "%d. %B %Y")
    end
  end
end

Liquid::Template.register_filter(Jekyll::DateDe)