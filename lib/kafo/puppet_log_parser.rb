module Kafo
  class PuppetLogParser
    def initialize
      @last_level = nil
    end

    def parse(line)
      method, message = case
                          when line =~ /^Error:(.*)/i || line =~ /^Err:(.*)/i
                            [:error, $1]
                          when line =~ /^Notice:(.*)/i
                            [:info, $1]
                          when line =~ /^Warning:(.*)/i || line =~ /^Debug:(.*)/i || line =~ /^Info:(.*)/i
                            [:debug, $1]
                          else
                            [@last_level.nil? ? :info : @last_level, line]
                        end

      if message.include?('Loading facts') && method != :error
        method = :debug
      end

      if message.include?('Applying configuration version')
        method = :debug
      end

      @last_level = method
      return [method, message.chomp.strip]
    end
  end
end
