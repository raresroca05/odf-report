module ODFReport

  class Calendar
    include Images, Nested

    TAG = '[[CALENDAR]]'.freeze

    def initialize(opts)
      @name = opts[:name]
      @period = opts[:period] || 'next-month'
      @start_day = opts[:start_day] || 0
      @header = opts[:header] || false
    end

    def replace!(content)

      calendar = generate_calendar

      txt = content.inner_html
      txt.gsub!(TAG, calendar)

      content.inner_html = txt

    end

    private

    def generate_calendar; end

  end

end