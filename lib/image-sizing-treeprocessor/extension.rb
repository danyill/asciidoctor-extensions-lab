require 'asciidoctor/extensions' unless RUBY_ENGINE == 'opal'
require 'fastimage'

include ::Asciidoctor

class ImageSizingTreeprocessor < Extensions::Treeprocessor
  def process document
    unless (image_blocks = document.find_by context: :image).nil_or_empty?

      image_blocks.each do |img|
        adjust_image(img, document)
      end

      # we also need to image images in a| table cells
      # this is not very elegant...
      table_blocks = document.find_by context: :table
      for t in table_blocks
        for acell in (t.rows.body + t.rows.foot).flatten.select {|c| c.attr?('style', :asciidoc) }
            for img in acell.inner_document.find_by context: :image
              adjust_image(img, document)
            end
        end
      end

    end
  end

  def adjust_image(img, document)
        # is this necessarily constant? could it be removed out of the loop or passed in?
        basedir =  (document.attr 'outdir') || ((document.respond_to? :options) && document.options[:to_dir])

        uri = img.image_uri(img.attributes['target'])
        uri_starts = ['http://', 'https://', 'ftp://']
        # absolute path for local files
        if ! uri.start_with?(*uri_starts)
          uri = File.join(basedir,uri)
        end

        width_want, height_want = nil

        # does asciidoctor sanitise input? not obviously to me
        width_want = (img.attributes['2'] if img.attributes.key? '2') \
                     || (img.attributes['width'] if img.attributes.key? 'width')

        height_want = (img.attributes['3'] if img.attributes.key? '3') \
                     || (img.attributes['height'] if img.attributes.key? 'height')

        width, height = FastImage.size(uri)

        #puts "Wanted: " + width_want.to_s + ' ' + height_want.to_s
        #puts "Have: " + width.to_s + ' ' + height.to_s

        # this always uses the image aspect ratio and any any user input
        # width (obviously) dominates
        if width_want
          img.attributes['width'] = width_want
          img.attributes['height'] = width_want.to_f/width*height
        elsif height_want
          img.attributes['width'] = height_want.to_f/height*width
          img.attributes['height'] = height_want
        else
          img.attributes['width'] = width
          img.attributes['height'] = height
        end
  end
end
