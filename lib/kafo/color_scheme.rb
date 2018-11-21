require 'highline/import'

module Kafo
  class ColorScheme

    def self.colors_possible?
      ::ENV['TERM'] && !`which tput 2> /dev/null`.empty? && `tput colors`.to_i > 0
    end

    def initialize(options={})
      @background = options[:background].nil? ? :dark : options[:background]
      @colors = options[:colors].nil? ? self.class.colors_possible? : options[:colors]
    end

    def setup
      HighLine.color_scheme = build_color_scheme
      if @colors
        HighLine.use_color = true
      else
        HighLine.use_color = false
      end
    end

    private

    def build_color_scheme
      HighLine::ColorScheme.new do |cs|
        color_hash.each do |key, value|
          cs[key] = value
        end
      end
    end

    def color_hash
      @color_hash ||= {
          :headline => build_color(:yellow),
          :title => build_color(:yellow),
          :horizontal_line => build_color(:white),
          :important => build_color(:white),
          :question => build_color(:green),
          :info => build_color(:cyan),
          :cancel => build_color(:red),
          :run => build_color(:green),

          :bad => build_color(:red),
          :good => build_color(:green),
      }
    end

    def build_color(color)
      bright = @background.to_s == 'bright'
      color = convert_bright_to_dark(color) if bright

      attributes = [ color ]
      attributes.unshift :bold unless bright
      attributes
    end

    def convert_bright_to_dark(color)
      case color
        when :white
          :black
        when :cyan
          :blue
        else
          color
      end
    end
  end
end
