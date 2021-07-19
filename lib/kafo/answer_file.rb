require 'kafo/answer_file/v1'

module Kafo
  module AnswerFile

    def self.load_answers(filename, version)
      case version
      when 1
        AnswerFile::V1.new(filename)
      else
        raise InvalidAnswerFileVersion
      end
    end

  end
end
