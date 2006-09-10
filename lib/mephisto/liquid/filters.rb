require 'digest/md5'
module Mephisto
  module Liquid
    module Filters
      include UrlMethods
      include ActionView::Helpers::TagHelper
      include ActionView::Helpers::AssetTagHelper

      def link_to_article(article)
        content_tag :a, article['title'], :href => article['url']
      end
      
      def link_to_page(page)
        content_tag :a, page_title(page), page_anchor_options(page)
      end

      def link_to_comments(article)
        content_tag :a, pluralize(article['comments_count'], 'comment'), :href => article['url']
      end
      
      def link_to_section(section)
        content_tag :a, section['name'], :href => section['url']
      end

      def page_title(page)
        page['is_page_home'] ? 'Home' : page['title']
      end

      def escape_html(html)
        CGI::escapeHTML(html)
      end
      
      alias h escape_html

      def pluralize(count, singular, plural = nil)
        "#{count} " + if count == 1
          singular
        elsif plural
          plural
        elsif Object.const_defined?(:Inflector)
          Inflector.pluralize(singular)
        else
          singular + "s"
        end
      end
      
      # See: http://starbase.trincoll.edu/~crypto/resources/LetFreq.html
      def word_count(text)
        (text.split(/[^a-zA-Z]/).join(' ').size / 4.5).round
      end

      def textilize(text)
        text.blank? ? '' : RedCloth.new(text).to_html
      end

      def format_date(date, format, ordinalized = false)
        if ordinalized
          date ? date.to_ordinalized_s(format.to_sym) : nil
        else
          date ? date.to_s(format.to_sym) : nil unless ordinalized
        end
      end
      
      def strftime(date, format)
        date ? date.strftime(format) : nil
      end
      
      def img_tag(img, options = {})
        tag 'img', {:src => asset_url(img), :alt => img.split('.').first }.merge(options)
      end
      
      def stylesheet_url(css)
        absolute_url :stylesheets, css
      end
      
      def javascript_url(js)
        absolute_url :javascripts, js
      end
      
      def asset_url(asset)
        absolute_url :images, asset
      end

      def stylesheet(stylesheet, media = nil)
        stylesheet << '.css' unless stylesheet.include? '.'
        tag 'link', :rel => 'stylesheet', :type => 'text/css', :href => stylesheet_url(stylesheet), :media => media
      end

      def javascript(javascript)
        javascript << '.js' unless javascript.include? '.'
        content_tag 'script', '', :type => 'text/javascript', :src => javascript_url(javascript)
      end
      
      def month_list
        # XXX cache this someday
        earliest = controller.site.articles.find(:first, :order => 'published_at').published_at.beginning_of_month
      end

      def gravatar(comment, size=80, default=nil)
        return '' unless comment['author_email']
        url = "http://www.gravatar.com/avatar.php?size=#{size}&gravatar_id=#{Digest::MD5.hexdigest(comment['author_email'])}"
        url << "&default=#{default}" if default

        image_tag url, :class => 'gravatar', :size => "#{size}x#{size}", :alt => comment['author']
      end

      private
        # marks a page as class=selected
        def page_anchor_options(page)
          options = {:href => page_url(page)}
          current_page_article.source == page.source ? options.update(:class => 'selected') : options
        end

        def page_url(page)
          page[:is_page_home] ? current_page_section.url : [current_page_section.url, page[:permalink]].join('/')
        end
        
        def current_page_section
          @current_page_section ||= outer_context(:section)
        end
        
        def current_page_article
          @current_page_article ||= outer_context(:article)
        end
        
        # pulls a variable out of the outermost context
        def outer_context(key)
          @context.assigns.last[key.to_s]
        end
    end
  end
end
