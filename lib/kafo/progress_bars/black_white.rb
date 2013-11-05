module Kafo
  module ProgressBars
    class BlackWhite < ProgressBar

      private

      def finite_template
        'Installing'.ljust(22) + ' ${<msg>} [${<percent>%}] [${<bar>}]'
      end

      def infinite_template
        'Preparing installation ${<msg>}'
      end

    end
  end
end
