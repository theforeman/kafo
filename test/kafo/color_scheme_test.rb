require 'test_helper'

module Kafo
  describe ColorScheme do
    let(:dark_colors) { { :colors => true, :background => :dark } }
    let(:bright_colors) { { :colors => true, :background => :bright } }
    let(:no_colors) { { :colors => false } }

    describe "#setup" do
      describe "without colors" do
        let(:color_scheme) { ColorScheme.new(no_colors) }
        before { color_scheme.setup }
        specify { refute HighLine.use_color? }
      end

      describe "with dark background colors" do
        let(:color_scheme) { ColorScheme.new(dark_colors) }
        before { color_scheme.setup }
        specify { assert HighLine.use_color? }
        let(:highline_color_scheme) { HighLine.color_scheme }
        specify { _(highline_color_scheme.keys).must_include 'good' }
        specify { _(highline_color_scheme.keys).must_include 'bad' }
        specify { _(highline_color_scheme.keys).must_include 'info' }
        specify { _(highline_color_scheme['info'].list).must_equal [:bold, :cyan] }
        specify { _(highline_color_scheme['horizontal_line'].list).must_equal [:bold, :white] }
      end

      describe "with bright background colors" do
        let(:color_scheme) { ColorScheme.new(bright_colors) }
        before { color_scheme.setup }
        specify { assert HighLine.use_color? }
        let(:highline_color_scheme) { HighLine.color_scheme }
        specify { _(highline_color_scheme.keys).must_include 'good' }
        specify { _(highline_color_scheme.keys).must_include 'bad' }
        specify { _(highline_color_scheme.keys).must_include 'info' }
        specify { _(highline_color_scheme['info'].list).must_equal [:blue] }
        specify { _(highline_color_scheme['horizontal_line'].list).must_equal [:black] }
      end
    end
  end
end
