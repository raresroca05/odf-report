module ODFReport

  class Link < Field

    def replace!(doc, data_item = nil)
      return unless node = find_link_node(doc)
      node.attribute('href').value = @value
    end

    private

    def find_link_node(doc)
      links = doc.xpath(".//text:a[imatches(@xlink:href, '^http(s)?:\/\/#{@name}\/?$')]", XPathWorkaround.new)
      links = doc.xpath(".//text:a[imatches(@xlink:href, '^http(s)?:\/\/#{@name}\/?$')]", XPathWorkaround.new)
      unless links.empty?
        return links.first
      end
      nil
    end


    class XPathWorkaround
      def imatches(node_set, regex)
        node_set.find_all { |node| node.value =~ /#{regex}/i }
      end
    end
  end

end
