module ODFReport

  module Images

    IMAGE_DIR_NAME = "Pictures"

    def find_image_name_matches(content)

      @images.each_pair do |image_name, path|
        if node = content.xpath("//draw:frame[@draw:name='#{image_name}']/draw:image").first
          placeholder_path = node.attribute('href').value
          @image_names_replacements[path] = ::File.join(IMAGE_DIR_NAME, ::File.basename(placeholder_path))
        end

        puts content.xpath(".//text:bookmark-start")
        puts image_name
        puts content.xpath(".//text:bookmark-start[text:name='#{image_name}']")
        if current_node = content.xpath(".//text:bookmark-start[@text:name='#{image_name}']").first
          while parent_node = current_node.next
            node = current_node.xpath("//draw:image").first
            puts node
            (current_node = current_node.next and next) if node.nil?
            placeholder_path = node.attribute('href').value
            @image_names_replacements[path] = ::File.join(IMAGE_DIR_NAME, ::File.basename(placeholder_path))
            puts 'replace'
            break
          end
        end
      end

    end

    def replace_images(file)

      return if @images.empty?

      @image_names_replacements.each_pair do |path, template_image|

        file.output_stream.put_next_entry(template_image)
        file.output_stream.write ::File.read(path)

      end

    end # replace_images

    # newer versions of LibreOffice can't open files with duplicates image names
    def avoid_duplicate_image_names(content)

      nodes = content.xpath("//draw:frame[@draw:name]")

      nodes.each_with_index do |node, i|
        node.attribute('name').value = "pic_#{i}"
      end

    end

  end

end
