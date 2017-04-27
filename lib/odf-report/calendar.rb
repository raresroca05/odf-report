
module ODFReport
  class Calendar

    TAG = '[[CALENDAR]]'.freeze
    VALID_PERIODS = %w{next-week next-month all-week all-month}
    WEEK = 7

    def initialize(opts)
      @period = opts[:period] || 'next-month'
      @start_day = opts[:start_day] || Date.today
      @header = opts[:header] || false
      @locale = opts[:locale] || 'en'
    end

    def replace!(content)
      puts generate_calendar
      calendar = generate_calendar

      txt = content.inner_html
      txt.gsub!(TAG, calendar)

      content.inner_html = txt

      # following is necessary because table is wrapped in <text:p>
      # for some reason it doesn't display the table when this is the case
      # possibly need to remove tag <text:to_s> but it seems harmless
      content.xpath('//text:p[table:table]').each do |node|
        node.replace(node.children)
      end

    end

    private

    def generate_calendar

      # GENERAL IDEA:
      # parse @period: validate if period is a valid period
      #                if next -> one iteration
      #                if all -> iterate till end-date of enrolment
      # start from start_day:
      #   -> take coming day that is a start_day (for example if start_day = 0 then next Sunday)
      #   -> if week: iterating = 7 times; if month: iterating = 31 times; count = start_day
      #   -> check for header and create header if set
      #   -> make row with days of week (internationalized...)
      #   -> make table row (rows = 1)
      #     -> if first row: create start_day empty columns
      #   -> fill in data in row = rows && column = count
      #   -> increment count MOD 7
      #   -> if count == 0 then increment rows

      return if (period = parse_period).nil?
      start_day = if period == WEEK
                    get_next_day(@start_day, 1) # next monday
                  else
                    @start_day.at_beginning_of_month.next_month
                  end

      table = Builder::XmlMarkup.new(indent: 2)
      table.tag!('table:table', 'table:name' => 'CALENDAR', 'table:style-name' => 'TABLE') do |table|
        # columns
        7.times do
          table.tag!('table:table-column', '')
        end

        # header
        table.tag!('table:table-row') do |row|
          7.times do |idx|
            row.tag!('table:table-cell', 'office:value-type' => 'string') do |cell|
              cell.tag!('text:p', Date::DAYNAMES[(idx + 1) % 7])
            end
          end
        end

        # content
        week_cursor = start_day.day - 1 % 7 # offset monday to 0 and sunday to 6
        current_day = start_day
        rows = 0
        end_day = start_day + period
        while current_day != end_day
          if week_cursor.zero? || (week_cursor.nonzero? && rows.zero?) # new row
            table.tag!('table:table-row') do |row|
              week_cursor.times do
                row.tag!('table:table-cell', 'office:value-type' => 'string')
              end
              puts "Some output plz: #{(end_day - current_day).to_i}"
              amount_days = if (end_day - current_day).to_i >= 7
                              7
                            else
                              (end_day - current_day).to_i
                            end
              (amount_days - week_cursor).times do
                row.tag!('table:table-cell', 'office:value-type' => 'string') do |cell|
                  cell.tag!('text:p', current_day)
                  current_day = current_day.next
                end
              end
            end
            week_cursor = 0
          end
          rows = rows.next
        end
      end

      puts start_day.day
      table.to_xml

    end

    def get_next_day(date, day_of_week)
      date + ((day_of_week - date.wday) % 7)
    end


    def parse_period
      period = @period
      return nil unless VALID_PERIODS.include? period
      if period.end_with? '-week'
        WEEK
      else
        days_in_month(@start_day.at_beginning_of_month.next_month.month,
                      @start_day.at_beginning_of_month.next_month.year)
      end
    end

    def days_in_month(month, year)
      Date.new(year, month, -1).day
    end

  end
end
