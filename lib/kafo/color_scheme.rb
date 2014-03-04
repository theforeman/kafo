require 'highline/import'

module Kafo
  class ColorScheme
    def initialize(config)
      @config = config
    end

    def setup
      if @config.app[:colors]
        HighLine.color_scheme = build_color_scheme
        HighLine.use_color = true
      else
        HighLine.use_color = false
      end
    end

    private

    def build_color_scheme
      HighLine::ColorScheme.new do |cs|
        color_hash.keys.each do |key|
          cs[key] = color_hash[key]
        end
      end
    end

    def color_hash
      @color_hash ||= {
          :headline => build_color(:yellow),
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
      bright = @config.app[:color_of_background].to_s == 'bright'
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
