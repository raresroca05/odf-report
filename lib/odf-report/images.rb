require 'rmagick'

module ODFReport

  module Images

    IMAGE_DIR_NAME = "Pictures"

    def update_images(file, original_zip_file)
      return if @images.empty?

      @image_name_additions.each_pair do |local_file, old_file|
        replaced_image_content = ::File.read(local_file)
        if original_zip_file
          entry = original_zip_file.find_entry(old_file)
          unless entry.nil?
            original_image = Magick::Image.from_blob(entry.get_input_stream.read)[0]
            new_image = Magick::Image.from_blob(replaced_image_content)[0]
            original_image_ratio = original_image.base_columns.to_f / original_image.base_rows.to_f
            new_image_ratio = new_image.base_columns.to_f / new_image.base_rows.to_f
            if original_image_ratio != new_image_ratio
              width, height = if original_image_ratio > new_image_ratio
                [new_image.base_columns.to_f * original_image_ratio / new_image_ratio, new_image.base_rows.to_f]
              else
                [new_image.base_columns.to_f, new_image.base_rows.to_f * new_image_ratio / original_image_ratio]
              end

              puts "ORIGINAL: #{new_image.base_columns.to_f}, #{new_image.base_rows.to_f}"
              puts "NEW: #{width}, #{height}"
              new_image.resize_to_fit!(width, height)
              empty_img = ::Magick::Image.new(width, height) { self.background_color = 'rgba(255,255,255,0)' }
              filled = empty_img.matte_floodfill(1, 1)
              filled.composite!(new_image, Magick::CenterGravity, ::Magick::OverCompositeOp)
              filled.format = original_image.format
              #filled.quality = original_image.quality
              replaced_image_content = filled.to_blob
            end
          else
            i_am_confused
          end
        end
        new_file = ::File.join(IMAGE_DIR_NAME, ::File.basename(local_file))
        file.output_stream.put_next_entry(new_file)
        file.output_stream.write(replaced_image_content)
      end
    end

    def update_manifest(content)

      return unless root_node = content.xpath("//manifest:manifest").first

      @image_name_additions.each_pair do |local_file, old_file|
        path = ::File.join(IMAGE_DIR_NAME, ::File.basename(local_file))
        next if root_node.xpath(".//manifest:file-entry[@manifest:full-path='#{path}']").first

        node = content.create_element('manifest:file-entry')
        node['manifest:full-path'] = path
        node['manifest:media-type'] = local_file.respond_to?(:content_type) ? local_file.content_type : MIME::Types.type_for(path)[0].content_type

        root_node.add_child node
      end

      @global_image_paths_set.each do |path|

        next if root_node.xpath(".//manifest:file-entry[@manifest:full-path='#{path}']").first

        node = content.create_element('manifest:file-entry')
        node['manifest:full-path'] = path
        node['manifest:media-type'] = MIME::Types.type_for(path)[0].content_type

        root_node.add_child node

      end

    end

    # newer versions of LibreOffice can't open files with duplicates image names
    def avoid_duplicate_image_names(content)
      nodes = content.xpath("//draw:frame[@draw:name]")
      nodes.each_with_index do |node, i|
        node.attribute('name').value = "pic_#{i}"
        node.xpath(".//draw:image").each do |draw_image|
          if !draw_image.attribute('href').nil?
            href =  draw_image.attribute('href').value
          end
          unless href.to_s.empty?
            @global_image_paths_set.add(href)
          end
        end
      end
    end

  end

end
