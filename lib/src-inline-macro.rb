RUBY_ENGINE == 'opal' ? (require 'src-inline-macro/extension') : (require_relative 'src-inline-macro/extension')

Asciidoctor::Extensions.register do
  if @document.basebackend? 'html'
    inline_macro SrcInlineMacro
    docinfo_processor SrcMacroAssetsDocinfoProcessor
  end
end
