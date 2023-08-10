# encoding: UTF-8
require 'forwardable'
require 'highline'
require 'yaml'

module Kafo
  class Wizard
    def self.utf_support?
      Kafo::ENV::LANG =~ /UTF-8\z/
    end

    extend Forwardable
    def_delegators :@highline, :agree, :ask, :choose, :say

    OK = utf_support? ? '✓' : 'y'
    NO = utf_support? ? '✗' : 'n'

    def initialize(kafo, input = $stdin, output = $stdout)
      @kafo   = kafo
      @config = kafo.config
      @name   = @config.app[:name] || 'Kafo'
      @highline = setup_terminal(input, output)
    end

    def run
      message = "Welcome to the #{@name} installer!"
      say(HighLine.color(message, :headline))
      say(HighLine.color('-' * message.size, :horizontal_line))
      say(<<END)

This wizard will gather all required information. You can change any parameter to your needs.

END

      exit 0 unless agree("\n<%= color('Ready to start?', :question) %> (y/n)", false)

      main_menu
    rescue Interrupt
      puts "Got interrupt, exiting"
      KafoConfigure.exit(130)
    end

    private

    def main_menu
      finished = false
      until finished
        say("\n" + HighLine.color('Main Config Menu', :headline))
        choose do |menu|
          menu.prompt = 'Choose an option from the menu... '
          menu.select_by = :index

          @config.modules.each do |mod|
            menu.choice "[#{mod.enabled? ? HighLine.color(OK, :run) : HighLine.color(NO, :cancel)}] Configure #{mod.name}" do
              configure_module(mod)
            end
          end
          menu.choice "Display current config" do
            display_hash
          end
          menu.choice HighLine.color('Save and run', :run) do
            KafoConfigure.config
            finished = true
          end
          menu.choice HighLine.color('Cancel run without Saving', :cancel) do
            say("Bye!")
            KafoConfigure.exit(0)
          end
        end
      end
    end

    def display_hash
      data = Hash[@config.modules.map { |mod| [mod.name, mod.enabled? ? mod.params_hash : false] }]
      say HighLine.color(YAML.dump(data), :info)
    end

    def configure_module(mod)
      go_back = false
      until go_back
        say("\n" + HighLine.color("Module #{mod.name} configuration", :headline))
        choose do |menu|
          menu.prompt = 'Choose an option from the menu... '
          menu.select_by = :index

          menu.choice("Enable/disable #{mod.name} module, current value: #{HighLine.color(mod.enabled?.to_s, :info)}") { turn_module(mod) }
          if mod.enabled?
            render_params(mod.primary_parameter_group.params, menu)

            others = (mod.primary_parameter_group.children + mod.other_parameter_groups).uniq
            others.each do |group|
              menu.choice("Configure #{group.formatted_name}") { configure_group(group) }
            end
            menu.choice("Reset a parameter to its default value") { reset_module_params(mod) }
          end
          menu.choice("Back to main menu") { go_back = true }
        end
      end
    end

    def configure_group(group)
      go_back = false
      until go_back
        say "\n" + HighLine.color("Group #{group.formatted_name} (of module #{group.module.name})", :headline)
        choose do |menu|

          render_params(group.params, menu)

          group.children.each do |subgroup|
            menu.choice("Configure #{subgroup.formatted_name}") { configure_group(subgroup) }
          end

          menu.choice("Back to parent menu") { go_back = true }
        end
      end
    end

    def render_params(params, menu)
      params.each do |param|
        if param.visible?(@kafo.params)
          menu.choice "Set #{HighLine.color(param.name, :important)}, current value: #{HighLine.color(param.value_to_s, :info)}" do
            configure(param)
          end
        end
      end
    end

    def configure(param)
      say "\n" + HighLine.color("Parameter #{param.name} (of module #{param.module.name})", :headline)
      say HighLine.color(param.doc.join("\n").gsub('"', '\"'), :important)
      say HighLine.color("Data type: #{param.type}", :important)
      value       = param.multivalued? ? configure_multi(param) : configure_single(param)
      value_was   = param.value
      param.value = value unless value.empty?

      until param.valid?
        param.value = value_was
        say "\n" + HighLine.color("Invalid value for #{param.name}", :important)
        param.validation_errors.each do |error|
          say "  " + HighLine.color(error, :important)
        end
        value       = param.multivalued? ? configure_multi(param) : configure_single(param)
        param.value = value unless value.empty?
      end
    end

    def configure_single(param)
      say "\ncurrent value: #{HighLine.color(param.value_to_s, :info)}"
      ask("new value:")
    end

    def configure_multi(param)
      say HighLine.color('every line is a separate value, blank line to quit, for hash use key:value syntax', :info)
      say "\ncurrent value: #{HighLine.color(param.value_to_s, :info)} %>"
      ask("new value:") do |q|
        q.gather = ""
      end

    end

    def turn_module(mod)
      agree("Enable #{mod.name} module? (y/n) ") ? mod.enable : mod.disable
    end

    def reset_module_params(mod)
      go_back = false
      until go_back
        say "\n" + HighLine.color("Resetting parameters of module #{mod.name}", :headline)
        choose do |menu|
          mod.params.each do |param|
            menu.choice "Reset #{HighLine.color(param.name, :important)}, current value: #{HighLine.color(param.value_to_s, :info)}, default value: #{HighLine.color(param.default_to_s, :info)}" do
              reset(param)
            end if param.visible?(@kafo.params)
          end
          menu.choice("Back to parent menu") { go_back = true }
        end
      end
    end

    def reset(param)
      param.unset_value
      say "\n" + HighLine.color("Value for #{param.name} reset to default", :important)
    end

    def setup_terminal(input, output)
      highline = HighLine.new(input, output)
      # HighLine 2 vs 1
      data = if highline.respond_to?(:terminal)
               highline.terminal.terminal_size
             else
               HighLine::SystemExtensions.terminal_size
             end
      highline.wrap_at = (data.first > 80) ? 80 : data.first if data.first
      highline.page_at = data.last if data.last
      highline
    end
  end
end
