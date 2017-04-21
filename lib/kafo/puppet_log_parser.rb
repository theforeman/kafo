module Kafo
  class PuppetLogParser
    def initialize
      @last_level = nil
    end

    def parse(line)
      line = normalize_encoding(line)
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

    private

    def normalize_encoding(line)
      if line.respond_to?(:encode) && line.respond_to?(:valid_encoding?)
        line.valid_encoding? ? line : line.encode('UTF-16be', :invalid => :replace, :replace => '?').encode('UTF-8')
      else  # Ruby 1.8.7, doesn't worry about invalid encodings
        line
      end
    end
  end
end
