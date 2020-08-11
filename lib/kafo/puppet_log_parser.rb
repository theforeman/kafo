module Kafo
  class PuppetLogParser
    def initialize
      @last_level = nil
      @loading_facts_line = false
    end

    def parse(line)
      if line =~ /^Info: Loading facts/i
        return [nil, nil] if @loading_facts_line

        @loading_facts_line = true
      end

      method, message = case
                          when line =~ /^Error:(.*)/i || line =~ /^Err:(.*)/i
                            [:error, $1]
                          when line =~ /^Warning:(.*)/i || line =~ /^Notice:(.*)/i
                            [:warn, $1]
                          when line =~ /^Info:(.*)/i
                            [:info, $1]
                          when line =~ /^Debug:(.*)/i
                            [:debug, $1]
                          else
                            [@last_level.nil? ? :info : @last_level, line]
                        end

      @last_level = method
      return [method, message.chomp]
    end
  end
end
