# frozen_string_literal: true

require 'asciidoctor/extensions' unless RUBY_ENGINE == 'opal'

include Asciidoctor

Asciidoctor::SyntaxHighlighter::HighlightJsAdapter.class_eval do
  # an adaptation of the SyntaxHighlighter::Base format method 
  # with the pre element removed
  def format_inline(node, lang, opts)
    class_attr_val = opts[:nowrap] ? %(#{@pre_class} highlight nowrap) : %(#{@pre_class} highlight inline #{lang ? %(lang-#{lang}) : ''})
    # TODO: What is transform?
    if (transform = opts[:transform])
      code = lang ? { 'data-lang' => lang } : {}
      transform[code]
      %(<code#{code.map { |k, v| %( #{k}="#{v}") }.join}>#{node.content}</code>)
    else
      %(<code#{lang ? %( data-lang="#{lang}" title="#{lang}" class="#{class_attr_val}") : ''}>#{node.content}</code>)
    end
  end
end

class SrcInlineMacro < Extensions::InlineMacroProcessor
  use_dsl

  named :src
  name_positional_attributes 'src'

  def process(parent, lang, attributes)
    doc = parent.document
    source = attributes['src']
    source_block = Block.new(parent, :paragraph, source: source, subs: :default) 
    if doc.syntax_highlighter.respond_to?(:format_inline)
      doc.syntax_highlighter.format_inline source_block, lang, {}
    else
      new_block = Inline.new(parent, context: :quoted, source: source, subs: :default)
      parent << new_block
      new_block.text()
      new_block.convert()
    end 
  end
end

class SrcMacroAssetsDocinfoProcessor < Extensions::DocinfoProcessor
  # For this I guess I could override the syntax highlighter docinfo method
  # but not cleanly like this...
  use_dsl
  # at_location :head

  def process(doc)
    unless doc.attributes['emoji'] == 'tortue'
      extdir = ::File.join(::File.dirname(__FILE__))
      stylesheet_name = 'src-inline-macro.css'
      if doc.attr? 'linkcss'
        stylesheet_href = handle_stylesheet doc, extdir, stylesheet_name
        style = %(<link rel="stylesheet" href="#{stylesheet_href}">)
      else
        content = doc.read_asset %(#{extdir}/#{stylesheet_name})
        style = ['<style>', content.chomp, '</style>'].join("\n")
      end
      script_content = %q(
      document.addEventListener('DOMContentLoaded', (event) => {
        document.querySelectorAll('code').forEach((block) => {
          hljs.highlightBlock(block);
        });
      });
      )
      script = ['<script>', script_content.chomp, '</script>'].join("\n")
      return [style, script].join("\n")

    end
  end

  def handle_stylesheet(doc, extdir, stylesheet_name)
    outdir = (doc.attr? 'outdir') ? (doc.attr 'outdir') : (doc.attr 'docdir')
    stylesoutdir = doc.normalize_system_path((doc.attr 'stylesdir'), outdir, (doc.safe >= SafeMode::SAFE ? outdir : nil))
    if stylesoutdir != extdir && doc.safe < SafeMode::SECURE && (doc.attr? 'copycss')
      destination = doc.normalize_system_path stylesheet_name, stylesoutdir, (doc.safe >= SafeMode::SAFE ? outdir : nil)
      content = doc.read_asset %(#{extdir}/#{stylesheet_name})
      ::File.open(destination, 'w') do |f|
        f.write content
      end
      destination
    else
      %(./#{stylesheet_name})
    end
  end
end
