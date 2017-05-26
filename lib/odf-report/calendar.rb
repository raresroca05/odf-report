module ODFReport
  class Calendar
    include Nested

    VALID_PERIODS = %w{week month}

    def initialize(opts)
      @period = opts[:period] || 'month'
      @start_day = opts[:start_day] ? Date.parse(opts[:start_day]) : Date.today
      @end_day = opts[:end_day] ? Date.parse(opts[:end_day]) : Date.today + 1.month
      @template = nil
      @fields = []
      @collection = opts[:collection] || []
      I18n.locale = opts[:locale] || 'en'
    end

    def replace!(content)
      # make the template
      puts "From #{@start_day} till #{@end_day}"
      create_calendar_style content
      define_template content
      # create and save the table, all cells are filled in with the template
      return {} unless @table = find_section_node(content)
      calendar = generate_calendar
      @table.inner_html = calendar

      # cleanup
      @table.xpath('//table:to_xml').each(&:remove)
      @table.xpath('//table:to_s').each(&:remove)
      @table.xpath('//table:table[table:table]').each do |node|
        node.replace(node.children)
      end

    end

    private

    def create_calendar_style(doc)
      style_root = doc.at(".//office:automatic-styles")
      table_style = Nokogiri::XML::Node.new('style:style', doc)
      table_style['style:name'] = 'BeepleCalendar'
      table_style['style:family'] = 'table'
      table_node = Nokogiri::XML::Node.new('style:table-properties', doc)
      table_node['style:width'] = '6.6924in'
      table_node['fo:margin-top'] = '0.09in'
      table_node['table:align'] = 'margins'
      table_style.add_child table_node

      row_style = Nokogiri::XML::Node.new('style:style', doc)
      row_style['style:name'] = 'BeepleCalendarRow'
      row_style['style:family'] = 'table-row'
      row_node = Nokogiri::XML::Node.new('style:table-row-properties', doc)
      row_node['style:min-row-height'] = '0.8694in'
      row_style.add_child row_node

      cell_style = Nokogiri::XML::Node.new('style:style', doc)
      cell_style['style:name'] = 'BeepleCalendarCell'
      cell_style['style:family'] = 'table-cell'
      cell_node = Nokogiri::XML::Node.new('style:table-cell-properties', doc)
      cell_node['fo:border'] = '0.25pt solid #000001'
      cell_node['fo:padding'] = '0.0375in'
      cell_style.add_child cell_node

      style_root.add_child table_style
      style_root.add_child row_style
      style_root.add_child cell_style
  end

    def generate_calendar

      table = Builder::XmlMarkup.new(indent: 2)
      table.tag!('table:table', 'table:name' => 'BeepleCalendar', 'table:style-name' => 'BeepleCalendar') do |table|
        # columns
        table.tag!('table:table-column', 'table:number-columns-repeated' => '7')

        # header
        table.tag!('table:table-row') do |row|
          7.times do |idx|
            row.tag!('table:table-cell', 'table:style-name' => 'BeepleCalendarCell', 'office:value-type' => 'string') do |cell|
              cell.tag!('text:p', I18n.t('days.day_names')[idx])
            end
          end
        end

        # content
        parse_period
        current_day = @start_day
        end_day = @end_day
        while current_day != end_day.next
          table.tag!('table:table-row', 'table:style-name' => 'BeepleCalendarRow') do |row|
            7.times do
              row.tag!('table:table-cell', 'table:style-name' => 'BeepleCalendarCell', 'office:value-type' => 'string') do |cell|
                cell.tag!('text:p', current_day)
                # p @collection["2017-06-07"]
                items = @collection[current_day.to_s]
                next if items.nil?
                generate_cell_node(cell, items)
              end
              current_day = current_day.next
            end
          end
        end
      end

      table.to_xml

    end

    def parse_period
      @start_day = @start_day.at_beginning_of_week
      @end_day = @end_day.at_end_of_week
    end

    def to_start_placeholder
      '{{CALENDAR}}'
    end

    def to_end_placeholder
      '{{/CALENDAR}}'
    end

    def define_template(doc)

      # selects all text:p nodes between calendar tags
      cell_markup_nodes = doc.xpath(".//*[self::text:span or self::text:p][contains(text(), '#{to_start_placeholder}')]/
                                          following::*[self::text:span or self::text:p][contains(text(), '#{to_end_placeholder}')]/
                                            preceding::*[text:span or text:p][
                                              preceding::*[self::text:span or self::text:p][contains(text(), '#{to_start_placeholder}')]
                                            ]")
      @template = cell_markup_nodes

    end

    def generate_cell_node(parent_node, collection)
      collection.each do |item|
        @template.each do |line|
          if line.children
            parent_node.tag!('text:p', 'text:style-name' => line.first[1]) do |p|
              line.children.each do |child|
                p.tag!('text:span', child.text, 'text:style-name' => child.attribute('style-name'))
              end
            end
          else
             parent_node.tag!('text:p', line.text, 'text:style-name' => line.attribute('style-name'))
          end
        end

        # template has been made, can now do textual substitute here
        # could we do add_field here?
        # IMPORTANT: VALUE CAN BE AN ARRAY OF HASHES!! => recursive call needed!
        # inside the do: if value.is_a? Array then loop over its hash the same way (can also need a recursive call)
        item.each_pair do |key, value|
          substitute_recursive value, parent_node if value.is_a? Array
          parent_node.to_s.gsub!("{{#{key.upcase}]}}", value.to_s)
        end
      end
    end

    def substitute_recursive(item, node)
      return if item.empty?
      item.first.each_pair do |key, value|
        substitute_recursive value, node if value.is_a? Array
        node.to_s.gsub! "{{#{key.upcase}}}", value.to_s
      end
    end

    def find_section_node(doc)

      possible_start_nodes = doc.xpath(".//*[contains(text(), '#{to_start_placeholder}')]")
      possible_end_nodes = doc.xpath(".//*[contains(text(), '#{to_end_placeholder}')]")

      return nil unless possible_start_nodes.length == 1
      return nil unless possible_end_nodes.length == 1

      start_node = possible_start_nodes.first
      end_node = possible_end_nodes.first

      first_common_ancestor = (start_node.ancestors & end_node.ancestors).first

      generated_section_node = doc.document.create_element('table:table')

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

      common_ancestor_end_index = end_node.ancestors.index(first_common_ancestor)
      parental_end_node = if common_ancestor_end_index == 0
                            end_node
                          else
                            end_node.ancestors[common_ancestor_end_index - 1]
                          end


      current_node = parental_start_node.next
      parental_start_node.after(generated_section_node)

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

    def split_node_front(node_to_split, _frontier_node)
      node_to_split
    end

    def split_node_back(node_to_split, _frontier_node)
      node_to_split
    end

  end
end
