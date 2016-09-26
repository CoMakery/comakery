require 'redcarpet/render_strip'

module Comakery
  class  Markdown
    include Singleton

    def self.to_html(markdown)
      return '' unless markdown
      instance.html.render(markdown)
    end

    def self.to_text(markdown)
      return '' unless markdown
      text = instance.text.render(markdown)
      text.gsub(/<.+?>/, '')  # remove HTML tags
    end

    def html
      return @html if @html

      html_renderer = RenderHtmlWithoutWrap.new(
        filter_html: true,
        no_images: true,
        no_styles: true,
        safe_links_only: true,
        link_attributes: {rel: 'nofollow', target: '_blank'}
      )
      @html = Redcarpet::Markdown.new(html_renderer, autolink: true)
    end

    def text
      @text ||= Redcarpet::Markdown.new(Redcarpet::Render::StripDown.new())
    end
  end

  class RenderHtmlWithoutWrap < Redcarpet::Render::HTML
    def postprocess(full_document)
      Regexp.new(/\A<p>(.*)<\/p>\Z/m).match(full_document)[1] rescue full_document
    end
  end
end
