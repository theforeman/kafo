#encoding: UTF-8
require 'test_helper'

CANCEL  = "3"  # "Cancel run without Saving"
CONFIRM = "4"  # "Save and run"


module Kafo
  describe Wizard do
    let(:input) { StringIO.new }
    let(:output) { StringIO.new }

    let(:puppet_module) { PuppetModule.new('puppet', TestParser.new(BASIC_MANIFEST)).parse }
    let(:kafo) do
      kafo                     = OpenStruct.new
      kafo.config              = KafoConfigure.config
      kafo.config.app[:name]   = 'Foreman'
      kafo.config.app[:colors] = false
      ColorScheme.new(kafo.config).setup

      kafo.config.instance_variable_set '@modules', [puppet_module]
      kafo.params = puppet_module.params
      kafo
    end

    let(:wizard) do
      wizard = Wizard.new(kafo)
      $terminal.instance_variable_set '@input', input
      $terminal.instance_variable_set '@output', output
      wizard
    end

    describe "#setup_termial" do
      describe "small terminal" do
        it "must configure correct width and preserve height" do
          HighLine::SystemExtensions.stub :terminal_size, [40, 10] do
            wizard.send :setup_terminal
            $terminal.wrap_at.must_equal 40
            $terminal.page_at.must_equal 10
          end
        end
      end

      describe "big terminal" do
        it "must configure max width to 80 and preserve height" do
          HighLine::SystemExtensions.stub :terminal_size, [100, 50] do
            wizard.send :setup_terminal
            $terminal.wrap_at.must_equal 80
            $terminal.page_at.must_equal 50
          end
        end
      end
    end

    describe "menu navigation" do
      describe "#run" do
        describe "print welcome message and finish" do
          before do
            input.puts 'n'
            input.rewind
          end

          it "exits with zero" do
            must_exit_with_code(0) { wizard.run }
          end

          it "uses app name" do
            must_exit_with_code(0) { wizard.run }
            must_be_on_stdout(output, 'Foreman')
          end
        end
      end

      describe "#main_menu" do
        before { input.puts 'y' }

        describe "list all modules, run installation and cancel options, then cancel" do
          before do
            input.puts CANCEL
            input.rewind
          end

          it "displays menu" do
            must_exit_with_code(0) { wizard.send :main_menu }
            must_be_on_stdout(output,
                              "Choose an option from the menu... ",
                              'Display current config',
                              'Save and run',
                              'Cancel run without Saving')
          end
        end

        describe "enter config dump" do
          before do
            input.puts '2' #'Display current config'
            input.puts CANCEL
            input.rewind
          end

          it "dumps yaml" do
            wizard.stub(:display_hash, Proc.new { say('hash was displayed') }) do
              must_exit_with_code(0) { wizard.send :main_menu }
            end
            must_be_on_stdout(output, 'hash was displayed')
          end
        end

        describe "enter module settings" do
          before do
            input.puts "1" # "[✓] Configure puppet"
            input.puts CANCEL
            input.rewind
          end

          it "configures module" do
            wizard.stub(:configure_module, Proc.new { say('puppet was configured') }) do
              must_exit_with_code(0) { wizard.send :main_menu }
            end
            must_be_on_stdout(output, 'puppet was configured')
          end
        end

        describe "run installation" do
          before do
            input.puts CONFIRM # "Save and run"
            input.rewind
          end

          it "exits after configuration from" do
            KafoConfigure.stub(:config, Proc.new { exit(0) }) do
              must_exit_with_code(0) { wizard.send :main_menu }
            end
          end
        end
      end

      describe "#display_hash" do
        it "dumps parameters" do
          wizard.send :display_hash
          must_be_on_stdout(output, 'puppet:', 'version: "1.0"')
        end
      end

      describe "#configure_module(mod)" do
        describe "turn module off" do
          before do
            puppet_module.enable
            puppet_module.enabled?.must_equal true
            input.puts "1" # "Enable/disable module"
            input.puts "n" # disable module
            input.puts "2" # "Back to main menu"
            input.rewind
          end

          it "changes module flag" do
            must_not_raise_eof(input, output) { wizard.send(:configure_module, puppet_module) }
            puppet_module.enabled?.must_equal false
          end
        end

        describe "turn module on" do
          before do
            puppet_module.disable
            puppet_module.enabled?.must_equal false
            input.puts "1" # Enable/disable module
            input.puts "y" # enable module
            input.puts "9" # "Back to main menu"
            input.rewind
          end

          it "changes module flag" do
            must_not_raise_eof(input, output) { wizard.send(:configure_module, puppet_module) }
            puppet_module.enabled?.must_equal true
          end
        end

        describe "configure subgroup" do
          before do
            puppet_module.enable
            input.puts "7" #"Configure Advanced parameters"
            input.puts "9" #"Back to main menu"
            input.rewind
          end

          it "executes configure_group(group)" do
            wizard.stub :configure_group, Proc.new { say('configure_group executed') } do
              must_not_raise_eof(input, output) { wizard.send(:configure_module, puppet_module) }
            end
            must_be_on_stdout(output, 'configure_group executed')
          end
        end

        describe "change parameter value" do
          before do
            puppet_module.enable
            input.puts "2" # "Set version, current value: 1.0"
            input.puts "9" # "Back to main menu"
            input.rewind
          end

          it "executes configure" do
            wizard.stub :configure, Proc.new { say('configure executed') } do
              must_not_raise_eof(input, output) { wizard.send(:configure_module, puppet_module) }
            end
            must_be_on_stdout(output, 'configure executed')
          end
        end
      end

      describe "#configure(param)" do
        describe "configure single parameter" do
          let(:single) { puppet_module.params.detect { |p| p.name == 'version' } }

          describe "valid change" do
            before do
              input.puts "changed"
              input.rewind
            end

            it "should change value" do
              wizard.send :configure, single
              single.value.must_equal('changed')
            end
          end

          describe "invalid change" do
            before do
              input.puts 'UNDEF'
              input.puts "2.0"
              input.rewind
            end

            it "should change value but warn on first try" do
              single.stub :valid?, Proc.new { single.value == '2.0' } do
                wizard.send :configure, single
                must_be_on_stdout(output, 'Invalid value')
                single.value.must_equal('2.0')
              end
            end
          end

          describe "empty input" do
            before do
              input.puts
              input.rewind
            end

            it "leaves original value untouched" do
              wizard.send :configure, single
              single.value.must_equal('1.0')
            end
          end
        end

        describe "configure multivalue parameter" do
          let(:array) { puppet_module.params.detect { |p| p.name == 'multivalue' } }
          describe "valid set" do
            before do
              input.puts "one"
              input.puts "two"
              input.puts "three"
              input.puts
              input.rewind
            end

            it "sets all three values" do
              wizard.send :configure, array
              array.value.must_equal ['one', 'two', 'three']
            end
          end
        end
      end

      describe "#configure_group(group)" do
        before do
          input.puts "Set debug, current value: true"
          input.puts "Back to parent menu"
          input.rewind
        end

        let(:advanced_group) do
          group = puppet_module.other_parameter_groups.detect { |g| g.name == 'Advanced parameters' }
          group.add_child OpenStruct.new(:formatted_name => 'testing')
          group
        end

        it "displays params of group and subgroups" do
          wizard.stub :configure, Proc.new { say('configure executed') } do
            wizard.send(:configure_group, advanced_group)
          end
          must_be_on_stdout(output, 'configure executed')
          must_be_on_stdout(output, 'debug', 'db_type', 'remote', 'server', 'username')
          wont_be_on_stdout(output, 'password', 'file') # because of condition
          must_be_on_stdout(output, 'Configure testing')
        end
      end

      describe "#render_params" do
        let(:visible) { Params::String.new(nil, 'visible').tap { |p| p.condition = 'true' } }
        let(:invisible) { Params::String.new(nil, 'invisible').tap { |p| p.condition = 'false' } }
        let(:params) { [visible, invisible] }

        before do
          input.puts 'cancel'
          input.rewind

          wizard.choose do |menu|
            wizard.send(:render_params, params, menu)
            menu.choice 'cancel'
          end
        end

        it "does not display params with false condition" do
          wont_be_on_stdout(output, 'invisible')
        end

        it "does display params with true condition" do
          must_be_on_stdout(output, 'visible')
        end
      end

    end
  end
end
