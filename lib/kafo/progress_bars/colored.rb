module Kafo
  module ProgressBars
    class Colored < ProgressBar

      def print_error(line)
        print ANSI::Code.red { line }
      end

      private

      def done_message
        ANSI::Code.green { super }
      end

      def finite_template
        'Installing'.ljust(22) +
            ANSI::Code.yellow { ' ${<msg>}' } +
            ANSI::Code.green { ' [${<percent>%}]' } +
            ((@term_width >= 83) ? ' [${<bar>}]' : '')
      end

      def infinite_template
        'Preparing installation' + ANSI::Code.yellow { ' ${<msg>}' }
      end

    end
  end
end
