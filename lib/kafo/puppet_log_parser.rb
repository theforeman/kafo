module Kafo
  class PuppetLogParser
    def initialize
      @last_level = nil
    end

    def parse(line)
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
