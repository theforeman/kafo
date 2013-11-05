# encoding: UTF-8
require 'highline/import'
require 'yaml'

module Kafo
  class Wizard
    def initialize(kafo)
      @kafo   = kafo
      @config = kafo.config
      @name   = @config.app[:name] || 'Kafo'
      setup_terminal
      setup_colors
    end

    def run
      message = "Welcome to the #{@name} installer!"
      say("<%= color('#{message}', :headline) %>")
      say("<%= color('#{'-' * message.size}', :horizontal_line) %>")
      say(<<END)

This wizard will gather all required information. You can change any parameter to your needs.

END

      exit 0 unless agree("\n<%= color('Ready to start?', :question) %> (y/n)", false)

      main_menu
    rescue Interrupt
      puts "Got interrupt, exiting"
      exit(0)
    end

    private

    def main_menu
      finished = false
      until finished
        say("\n<%= color('Main Config Menu', :headline) %>")
        choose do |menu|
          menu.prompt = 'Choose an option from the menu... '
          @config.modules.each do |mod|
            menu.choice "[#{mod.enabled? ? '✓' : '✗'}] Configure #{mod.name}" do
              configure_module(mod)
            end
          end
          menu.choice "Display current config" do
            display_hash
          end
          menu.choice "<%= color('Save and run', :run) %>" do
            KafoConfigure.config
            finished = true
          end
          menu.choice "<%= color('Cancel run without Saving', :cancel) %>" do
            say("Bye!"); exit 0
          end
        end
      end
    end

    def display_hash
      data = Hash[@config.modules.map { |mod| [mod.name, mod.enabled? ? mod.params_hash : false] }]
      say "<%= color('#{YAML.dump data}', :info) %>"
    end

    def configure_module(mod)
      go_back = false
      until go_back
        say("\n<%= color('Module #{mod.name} configuration', :headline) %>")
        choose do |menu|
          menu.prompt = 'Choose an option from the menu... '
          menu.choice("Enable/disable #{mod.name} module, current value: <%= color('#{mod.enabled?}', :info) %>") { turn_module(mod) }
          if mod.enabled?
            render_params(mod.primary_parameter_group.params, menu)

            others = mod.primary_parameter_group.children + mod.other_parameter_groups
            others.each do |group|
              menu.choice("Configure #{group.formatted_name}") { configure_group(group) }
            end
          end
          menu.choice("Back to main menu") { go_back = true }
        end
      end
    end

    def configure_group(group)
      go_back = false
      until go_back
        say "\n<%= color('Group #{group.formatted_name} (of module #{group.module.name})', :headline) %>"
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
          menu.choice "Set <%= color('#{param.name}', :important) %>, current value: <%= color('#{param.value}', :info) %>" do
            configure(param)
          end
        end
      end
    end

    def configure(param)
      say "\n<%= color('Parameter #{param.name} (of module #{param.module.name})', :headline) %>"
      say "<%= color(\"#{param.doc.join("\n").gsub('"', '\"')}\", :important) %>"
      value       = param.multivalued? ? configure_multi(param) : configure_single(param)
      value_was   = param.value
      param.value = value unless value.empty?

      until param.valid?
        param.value = value_was
        say "\n<%= color('Invalid value for #{param.name}', :important) %>"
        value       = param.multivalued? ? configure_multi(param) : configure_single(param)
        param.value = value unless value.empty?
      end
    end

    def configure_single(param)
      say "\ncurrent value: <%= color('#{param.value}', :info) %>"
      ask("new value:")
    end

    def configure_multi(param)
      say "<%= color('every line is a separate value, blank line to quit', :info) %>"
      say "\ncurrent value: <%= color('#{param.value}', :info) %>"
      ask("new value:") do |q|
        q.gather = ""
      end

    end

    def turn_module(mod)
      agree("Enable #{mod.name} module? (y/n) ") ? mod.enable : mod.disable
    end

    def setup_terminal
      $terminal         = HighLine.new
      data              = HighLine::SystemExtensions.terminal_size
      $terminal.wrap_at = data.first > 80 ? 80 : data.first
      $terminal.page_at = data.last
    end

    # setup colour scheme for prompts
    def setup_colors
      colors = HighLine::ColorScheme.new do |cs|
        cs[:headline]        = [:bold, :yellow, :on_black]
        cs[:horizontal_line] = [:bold, :white, :on_black]
        cs[:important]       = [:bold, :white, :on_black]
        cs[:question]        = [:bold, :green, :on_black]
        cs[:info]            = [:bold, :cyan, :on_black]
        cs[:cancel]          = [:bold, :red, :on_black]
        cs[:run]             = [:bold, :green, :on_black]
      end

      nocolors = HighLine::ColorScheme.new do |cs|
        colors.keys.each { |k| cs[k.to_sym] = [] }
      end

      HighLine.color_scheme = @config.app[:colors] ? colors : nocolors
    end
  end
end
