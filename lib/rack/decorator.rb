require 'uri'
require 'rack'
require 'nokogiri'

module Rack
  
  class Decorator
    
    VERSION = '0.0.2'
    
    attr_accessor :use_jquery
    attr_accessor :use_fancyzoom
    attr_accessor :scripts
    attr_accessor :stylesheets
    attr_accessor :feed_link
    
    def initialize(app, options={})
      @app = app
      options.each { |key, value| method("#{key}=").call(value) }
      @stylesheets ||= []
      @scripts ||= []
      if @use_jquery || @use_fancyzoom
        @scripts << URI.parse('http://ajax.googleapis.com/ajax/libs/jquery/1.6.1/jquery.min.js')
      end
      if @use_fancyzoom
        @scripts += [
          URI.parse('/javascript/jqueryfancyzoom/jquery.shadow.js'),
          URI.parse('/javascript/jqueryfancyzoom/jquery.ifixpng.js'),
          URI.parse('/javascript/jqueryfancyzoom/jquery.fancyzoom.min.js'),
          %q{
            $(function() {
              $.fn.fancyzoom.defaultsOptions.imgDir = '/images/jqueryfancyzoom/';  // very important must finish with a /
              $('a.fancyzoom').fancyzoom();
            });
          }
        ]
      end
    end
    
    def head(html, src_html)
      html.title(src_html.at_xpath('//h1').content)
    end
    
    def body(html, src_html)
      if (body = src_html.xpath('//body'))
        html << body.children.to_html
      else
        html << src_html
      end
    end
    
    def scripts(html)
      @scripts.each do |script|
        case script
        when URI, %r{^(/\w|https?:)}
          html.script('', :src => script.to_s, :type => 'text/javascript')
        when String
          html.script(:type => 'text/javascript') { html << script }
        else
          raise "Can't build script tag with #{script.class} object"
        end
      end
    end
    
    def stylesheets(html)
      @stylesheets.each do |stylesheet|
        case stylesheet
        when URI, %r{^(/|https?:)}
          html.link(:href => stylesheet.to_s, :rel => 'stylesheet', :type => 'text/css')
        when String
          html.style(:type => 'text/css') { html << stylesheet }
        else
          raise "Can't build stylesheet tag with #{stylesheet.class} object"
        end
      end
    end
    
    def decorate(response)
      src_html = Nokogiri::HTML.parse(response.body.join)
      builder = Nokogiri::HTML::Builder.new(:encoding => 'UTF-8') do |html|
        html.html(:lang => 'en') do
          html.head do
            head(html, src_html)
            scripts(html)
            stylesheets(html)
            if @feed_link
              html.link(:rel => 'alternate', :type => 'application/atom+xml', :title => @feed_link.title, :href => @feed_link.uri)
            end
          end
          html.body(:lang => 'en') do
            body(html, src_html)
          end
        end
      end
      response.body = [builder.doc.to_s]
      response.header.delete('Content-Length')
    end
    
    def call(env)
      response = @app.call(env)
      response = Rack::Response.new(response[2], response[0], response[1]) if response.kind_of?(Array)
      decorate(response) if response.header['Content-Type'] =~ %r{^text/html}
      response.finish
    end

  end
  
end