require 'powerbar'
require 'ansi/code'

class ProgressBar
  def initialize
    @lines                                    = 0
    @all_lines                                = 0
    @total                                    = :unknown
    @bar                                      = PowerBar.new
    @bar.settings.tty.infinite.template.main  = infinite_template
    @bar.settings.tty.finite.template.main    = finite_template
    @bar.settings.tty.finite.template.padchar = ' '
    @bar.settings.tty.finite.template.barchar = '.'
    @bar.settings.tty.finite.output           = Proc.new { |s| $stderr.print s }
  end

  def update(line)
    @total     = $1.to_i if line =~ /\w*START (\d+)/
    @lines     += 1 if line.include?('RESOURCE') && @lines < @total - 1
    @all_lines += 1

    # we print every 20th line during installation preparing otherwise we update every line
    if @all_lines % 20 == 0 || @total != :unknown
      @bar.show({ :msg   => format(line),
                  :done  => @lines,
                  :total => @total })
    end
  end

  def close
    @bar.show({ :msg   => ANSI::Code.green { 'Done' + (' ' * 46) },
                :done  => @total == :unknown ? @bar.done + 1 : @total,
                :total => @total }, true)
    @bar.close
  end

  def print(line)
    @bar.print line
  end

  private

  def format(line)
    (line.tr("\r\n", '') + (' ' * 50))[0..49]
  end

  def finite_template
    'Installing'.ljust(22) +
        ANSI::Code.yellow { ' ${<msg>}' } +
        ANSI::Code.green { ' [${<percent>%}]' } +
        ' [${<bar>}]'
  end

  def infinite_template
    'Preparing installation' + ANSI::Code.yellow { ' ${<msg>}' }
  end
end
