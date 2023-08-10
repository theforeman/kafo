# encoding: UTF-8
require 'highline'
require 'powerbar'
require 'ansi/code'
require 'set'

module Kafo
# Progress bar base class
#
# To define new progress bar you can inherit from this class and implement
# #finite_template and #infinite_template methods. Also you may find useful to
# change more methods like #done_message or #print_error
  class ProgressBar
    MONITOR_RESOURCE = %r{\w*MONITOR_RESOURCE ([^\]]+\])}
    EVALTRACE_START = %r{/(.+\]): Starting to evaluate the resource}
    EVALTRACE_END = %r{/(.+\]): Evaluated in [\d\.]+ seconds}
    PREFETCH = %r{Prefetching .* resources for}

    def initialize
      @lines                                    = 0
      @all_lines                                = 0
      @total                                    = :unknown
      @resources                                = Set.new
      @term_width                               = terminal_width
      @bar                                      = PowerBar.new
      @bar.settings.tty.infinite.template.main  = infinite_template
      @bar.settings.tty.finite.template.main    = finite_template
      @bar.settings.tty.finite.template.padchar = ' '
      @bar.settings.tty.finite.template.barchar = '.'
      @bar.settings.tty.finite.output           = Proc.new { |s| $stderr.print s }
    end

    def update(line)
      @all_lines += 1

      # we print every 20th line during installation preparing otherwise only update at EVALTRACE_START
      update_bar = (@total == :unknown && @all_lines % 20 == 0)
      force_update = false

      if (line_monitor = MONITOR_RESOURCE.match(line))
        @resources << line_monitor[1]
        @total = ((@total == :unknown) ? 1 : @total + 1)
      end

      if (line_start = EVALTRACE_START.match(line))
        if (known_resource = find_known_resource(line_start[1]))
          line = known_resource
          update_bar = true
          force_update = true
        end
      end

      if (line_end = EVALTRACE_END.match(line)) && @total != :unknown && @lines < @total
        if (known_resource = find_known_resource(line_end[1]))
          @resources.delete(known_resource)  # ensure it's only counted once
          @lines += 1
        end
      end

      if PREFETCH =~ line
        update_bar = true
        force_update = true
      end

      if update_bar
        @bar.show({ :msg   => format(line),
                    :done  => @lines,
                    :total => @total }, force_update)
      end
    end

    def close
      @bar.show({ :msg   => done_message,
                  :done  => (@total == :unknown) ? @bar.done + 1 : @total,
                  :total => @total }, true)
      @bar.close
    end

    def print(line)
      @bar.print line
    end

    def print_error(line)
      print line
    end

    private

    def terminal_width
      # HighLine 2 has Terminal, 1 has SystemExtensions
      terminal_size = if HighLine.respond_to?(:default_instance)
                        HighLine.default_instance.terminal.terminal_size
                      else
                        HighLine::SystemExtensions.terminal_size
                      end

      terminal_size ? (terminal_size[0] || 0) : 0
    end

    def done_message
      text = 'Done'
      text + (' ' * (50 - text.length))
    end

    def format(line)
      (line.tr("\r\n", '') + (' ' * 50))[0..49]
    end

    def finite_template
      'Installing... [${<percent>%}]'
    end

    def infinite_template
      'Installing...'
    end

    def find_known_resource(resource)
      loop do
        return resource if @resources.include?(resource)
        # continue to remove prefixes from /Stage[main]/Example/File[/etc/foo] until a resource name is found
        break unless resource.include?('/')
        resource = resource.sub %r{.*?/}, ''
      end
      nil
    end

  end
end

require 'kafo/progress_bars/colored'
require 'kafo/progress_bars/black_white'
