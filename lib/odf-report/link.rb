module ODFReport

  class Link < Field

    def replace!(doc, data_item = nil)
      return unless node = find_link_node(doc)
      node.attribute('href').value = @value
    end

    private

    def find_link_node(doc)
      links = doc.xpath(".//text:a[@xlink:href='http://#{@name}/']")
      if links.empty?
        links = doc.xpath(".//text:a[@xlink:href='https://#{@name}/']")
      end

      unless links.empty?
        return links.first
      end
      nil
    end

  end

end
