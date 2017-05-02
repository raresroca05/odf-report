module ODFReport
  class Calendar
    include Nested

    VALID_PERIODS = %w{next-week next-month all-week all-month}
    WEEK = 7

    def initialize(opts)
      @period = opts[:period] || 'next-month'
      @start_day = opts[:start_day] || Date.today
      @end_day = nil
      @header = opts[:header] || false
      @locale = opts[:locale] || 'en'
      @template = nil
      @fields = []
      @collection_field = opts[:collection_field]
      @collection = opts[:collection]
    end

    def replace!(content, doc, row = nil)

      # make the template
      define_template content
      # create and save the table, all cells are filled in with the template
      return {} unless @table = find_section_node(content)
      calendar = generate_calendar
      puts "Table node: #{@table}"
      @table.inner_html = calendar

      # cleanup
      @table.xpath('//table:to_xml').each(&:remove)
      @table.xpath('//table:to_s').each(&:remove)
      @table.xpath('//table:table[table:table]').each do |node|
        node.replace(node.children)
      end

      # now: replace all the tags
      # problem: shouldn't this be done on a cell per cell basis?
      # -> immediate replace in generate_cell instead? (probably)

    end

    private

    def generate_calendar

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
        parse_period
        current_day = @start_day
        end_day = @end_day
        while current_day != end_day.next
          table.tag!('table:table-row') do |row|
            7.times do
              row.tag!('table:table-cell', 'office:value-type' => 'string') do |cell|
                cell.tag!('text:p', current_day)
                # items = @collection[current_day.to_s.to_sym]
                test_items = [:event_name => 'Team1', :event_location => 'Brussels']
                # next if items.empty?
                generate_cell_node(cell, current_day.month, test_items)
                current_day = current_day.next
              end
            end
          end
        end
      end

      table.to_xml

    end

    def get_next_day(date, day_of_week)
      date + ((day_of_week - date.wday) % 7)
    end


    def parse_period
      period = @period
      return nil unless VALID_PERIODS.include? period
      if period.end_with? 'week'
        @month = @start_day.month
        @start_day = @start_day.at_beginning_of_week.next_week
        @end_day = @start_day.at_end_of_week
      else
        month = @start_day.at_beginning_of_month.next_month
        @month = month.month
        @start_day = month.at_beginning_of_week
        @end_day = month.at_end_of_month.at_end_of_week
      end
    end

    def days_in_month(month, year)
      Date.new(year, month, -1).day
    end

    def to_start_placeholder
      '[[CALENDAR]]'
    end

    def to_end_placeholder
      '[[/CALENDAR]]'
    end

    def define_template(doc)

      # selects all text:p nodes between calendar tags
      cell_markup_nodes = doc.xpath(".//text:p[contains(text(), '#{to_start_placeholder}')]/
                                          following-sibling::text:p[contains(text(), '#{to_end_placeholder}')]/
                                            preceding-sibling::text:p[
                                              preceding-sibling::text:p[contains(text(), '#{to_start_placeholder}')]
                                            ]")
      @template = cell_markup_nodes

    end

    def generate_cell_node(parent_node, month, collection)
      return unless @month == month
      collection.each do |item|
        @template.each do |line|
          parent_node.tag!('text:p', line.text, 'text:style-name' => line.first[1])
        end
        # template has been made, can now do textual substitute here
        # could we do add_field here?
        item.each_pair { |key, value| parent_node.to_s.gsub!("[#{key.upcase}]", value) }
      end
    end

    def find_section_node(doc)

      possible_start_nodes = doc.xpath(".//*[contains(text(), '#{to_start_placeholder}')]")
      possible_end_nodes = doc.xpath(".//*[contains(text(), '#{to_end_placeholder}')]")

      puts "FOUND START #{possible_start_nodes.length} NODES for CALENDAR"
      puts "FOUND END #{possible_end_nodes.length} NODES for CALENDAR"

      return nil unless possible_start_nodes.length == 1
      return nil unless possible_end_nodes.length == 1

      puts "FOUND possible candidates for CALENDAR"

      start_node = possible_start_nodes.first
      end_node = possible_end_nodes.first

      puts "Ancestors for start node #{start_node.ancestors.map(&:name)}"
      puts "Ancestors for end node #{end_node.ancestors.map(&:name)}"

      first_common_ancestor = (start_node.ancestors & end_node.ancestors).first

      puts "FIRST COMMON ANCESTOR is #{first_common_ancestor.namespace.prefix}"

      generated_section_node = doc.document.create_element('table:table')
      # generated_section_node.inner_html = generate_calendar
      puts "GENERATED SECTION NODE is #{generated_section_node.inspect}"

      # Effectively we are going to copy all relevant nodes to a new generated section node
      # This will be done in a few steps
      #  A) We find the parental_start_node. This is a child node of the common ancestor node
      #     which contains the start_node. This can be the start_node itself
      #  B) We find the parental_end_node similar to the parental_start_node
      #  C) We move all nodes between parental_start_node and parental_end_node
      #  D) We split the parental_start_node in 2 parts. The first part is every node before the
      #      start_node. The second part are all the nodes aftert the start node, including the start_node
      #      Duplicates of the parental structure are made.
      #      REMARK: This is a potential intrusive and destructive operation. If the start node
      #              is part of a table we probably will break the table layout.
      #  E) Similar for the parental_end_node


      common_ancestor_start_index = start_node.ancestors.index(first_common_ancestor)
      parental_start_node = if common_ancestor_start_index == 0
                              start_node
                            else
                              start_node.ancestors[common_ancestor_start_index - 1]
                            end
      puts "PARENTAL START NODE: #{parental_start_node}"

      common_ancestor_end_index = end_node.ancestors.index(first_common_ancestor)
      parental_end_node = if common_ancestor_end_index == 0
                            end_node
                          else
                            end_node.ancestors[common_ancestor_end_index - 1]
                          end

      puts "PARENTAL END NODE: #{parental_end_node}"

      current_node = parental_start_node.next
      parental_start_node.after(generated_section_node)
      puts "Pasted something after parental start and now it's #{parental_start_node}"

      generated_section_node.add_child(
          split_node_front(parental_start_node, start_node)
      )

      while current_node != parental_end_node
        next_node = current_node.next
        current_node.remove
        current_node = next_node
      end

      generated_section_node.add_child(
          split_node_back(parental_end_node, end_node)
      )

      start_node.remove
      end_node.remove

      generated_section_node
    end

    def get_table_node
      node = @table.dup

      name = node.get_attribute('text:name').to_s
      @idx ||=0; @idx +=1
      node.set_attribute('text:name', "#{name}_#{@idx}")

      node
    end

    def split_node_front(node_to_split, _frontier_node)
      node_to_split
    end

    def split_node_back(node_to_split, _frontier_node)
      node_to_split
    end

  end
end
