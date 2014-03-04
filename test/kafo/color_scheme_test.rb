require 'test_helper'

module Kafo
  describe ColorScheme do
    let(:config) { Struct.new(:app) }
    let(:config_dark_colors) { config.new(:colors => true) }
    let(:config_bright_colors) { config.new(:colors => true, :color_of_background => :bright) }
    let(:config_no_colors) { config.new(:colors => false) }

    describe "#setup" do
      describe "without colors" do
        let(:color_scheme) { ColorScheme.new(config_no_colors) }
        before { color_scheme.setup }
        specify { refute HighLine.use_color? }
      end

      describe "with dark background colors" do
        let(:color_scheme) { ColorScheme.new(config_dark_colors) }
        before { color_scheme.setup }
        specify { assert HighLine.use_color? }
        let(:highline_color_scheme) { HighLine.color_scheme }
        specify { highline_color_scheme.keys.must_include 'good' }
        specify { highline_color_scheme.keys.must_include 'bad' }
        specify { highline_color_scheme.keys.must_include 'info' }
        specify { highline_color_scheme['info'].list.must_equal [:bold, :cyan] }
        specify { highline_color_scheme['horizontal_line'].list.must_equal [:bold, :white] }
      end

      describe "with bright background colors" do
        let(:color_scheme) { ColorScheme.new(config_bright_colors) }
        before { color_scheme.setup }
        specify { assert HighLine.use_color? }
        let(:highline_color_scheme) { HighLine.color_scheme }
        specify { highline_color_scheme.keys.must_include 'good' }
        specify { highline_color_scheme.keys.must_include 'bad' }
        specify { highline_color_scheme.keys.must_include 'info' }
        specify { highline_color_scheme['info'].list.must_equal [:blue] }
        specify { highline_color_scheme['horizontal_line'].list.must_equal [:black] }
      end
    end
  end
end
