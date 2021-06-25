module ODFReport

  class Image

    DELIMITERS = %w([ ])
    IMAGE_DIR_NAME = "Pictures"

    def initialize(opts, &block)
      @name = opts[:name]
      @data_image = opts[:data_image]

      unless @value = opts[:value]

        if block_given?
          @block = block

        else
          @block = lambda { |item| self.extract_value(item) }
        end

      end

    end

    def replace!(content, data_item = nil)
      old_file = ''

      if node = content.xpath("//draw:frame[@draw:name='#{@name}']/draw:image").first
        path = get_value(data_item)

        if path.nil?
          return
        end

        if path.respond_to?(:call)
          path = path.call
          return if path.blank?
        end

        placeholder_path = node.attribute('href').value
        node.attribute('href').value = ::File.join(IMAGE_DIR_NAME, ::File.basename(path))
        old_file = ::File.join(IMAGE_DIR_NAME, ::File.basename(placeholder_path))
      else
        if current_node = content.xpath(".//text:bookmark-start[@text:name='#{@name}']").first
          path = get_value(data_item)

          if path.blank?
            return
          end

          if path.respond_to?(:call)
            path = path.call
            return if path.blank?
          end

          while current_node = current_node.next
            node = current_node.xpath(".//draw:image").first
            next if node.nil?

            return nil if node.attribute('odf-report-replaced')&.value == 'true'

            placeholder_path = node.attribute('href').value
            node.attribute('href').value = ::File.join(IMAGE_DIR_NAME, ::File.basename(path))
            node.set_attribute('odf-report-replaced', 'true')
            old_file = ::File.join(IMAGE_DIR_NAME, ::File.basename(placeholder_path))

            break
          end
        else
          return nil
        end
      end

      {path=>old_file}
    end

    def get_value(data_item = nil)
      @value || @block.call(data_item) || nil
    end

    def extract_value(data_item)
      return unless data_item
      key = @data_image || @name
      if data_item.is_a?(Hash)
        data_item[key] || data_item[key.to_s.downcase] || data_item[key.to_s.upcase] || data_item[key.to_s.downcase.to_sym]

      elsif data_item.respond_to?(key.to_s.downcase.to_sym)
        data_item.send(key.to_s.downcase.to_sym)

      else
        raise "Can't find image [#{key}] in this #{data_item.class}"

      end

    end

    private

    def to_placeholder
      if DELIMITERS.is_a?(Array)
        "#{DELIMITERS[0]}#{@name.to_s.upcase}#{DELIMITERS[1]}"
      else
        "#{DELIMITERS}#{@name.to_s.upcase}#{DELIMITERS}"
      end
    end

    def sanitize(txt)
      txt = html_escape(txt)
      txt = odf_linebreak(txt)
      txt
    end

    HTML_ESCAPE = { '&' => '&amp;',  '>' => '&gt;',   '<' => '&lt;', '"' => '&quot;' }

    def html_escape(s)
      return "" unless s
      s.to_s.gsub(/[&"><]/) { |special| HTML_ESCAPE[special] }
    end

    def odf_linebreak(s)
      return "" unless s
      s.to_s.gsub("\n", "<text:line-break/>")
    end



  end
end
