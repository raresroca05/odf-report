module ODFReport

  class PoormanSection
    include Images, Nested

    def initialize(opts)
      @name             = opts[:name]
      @collection_field = opts[:collection_field]
      @collection       = opts[:collection]

      @fields = []
      @texts = []
      @tables = []
      @sections = []
      @poorman_sections = []
      @images = []
      @image_name_additions = {}
    end

    def replace!(doc, file, row = nil)

      return {} unless @section_node = find_section_node(doc)

      @collection = get_collection_from_item(row, @collection_field) if row

      @collection.each do |data_item|

        new_section = get_section_node

        @sections.each { |s| @image_name_additions.merge! s.replace!(new_section, file, data_item) }

        @poorman_sections.each { |s| @image_name_additions.merge! s.replace!(new_section, file, data_item) }

        @tables.each   { |t| @image_name_additions.merge! t.replace!(new_section, file, data_item) }

        @texts.each    { |t| t.replace!(new_section, data_item) }

        replace_fields(new_section, data_item)

        @images.each   { |i| x = i.replace!(new_section, data_item); x.nil? ? nil : (@image_name_additions.merge! x) }

        @section_node.before(new_section)

      end

      @section_node.remove

      update_images(file)

      @image_name_additions

    end # replace_section

  private

    def find_section_node(doc)

      possible_start_nodes = doc.xpath(".//*[contains(text(), '#{to_start_placeholder}')]")
      possible_end_nodes = doc.xpath(".//*[contains(text(), '#{to_end_placeholder}')]")

      puts "FOUND START #{possible_start_nodes.length} NODES for #{@name}"
      puts "FOUND END #{possible_end_nodes.length} NODES for #{@name}"

      return nil unless possible_start_nodes.length == 1
      return nil unless possible_end_nodes.length == 1

      puts "FOUND possible candidates for #{@name}"

      start_node = possible_start_nodes.first
      end_node = possible_end_nodes.first

      puts "Ancestors for start node #{start_node.ancestors.map(&:name)}"
      puts "Ancestors for end node #{end_node.ancestors.map(&:name)}"

      first_common_ancestor = (start_node.ancestors & end_node.ancestors).first

      puts "FIRST COMMON ANCESTOR is #{first_common_ancestor.namespace.prefix}"

      generated_section_node = doc.document.create_element('text:section')

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
        generated_section_node.add_child(current_node)
        current_node = next_node
      end

      generated_section_node.add_child(
        split_node_back(parental_end_node, end_node)
      )

      start_node.inner_html = start_node.inner_html.gsub!(/#{to_start_placeholder}/, '')
      end_node.inner_html = end_node.inner_html.gsub!(/#{to_end_placeholder}/, '')

      return generated_section_node
    end

    def get_section_node
      node = @section_node.dup

      name = node.get_attribute('text:name').to_s
      @idx ||=0; @idx +=1
      node.set_attribute('text:name', "#{name}_#{@idx}")

      node
    end

    def to_start_placeholder
      "{{#{@name}}}"
    end

    def to_end_placeholder
      "{{/#{@name}}}"
    end

    def split_node_front(node_to_split, frontier_node)
      return node_to_split
    end

    def split_node_back(node_to_split, frontier_node)
      return node_to_split
    end

  end

end
