# encoding: UTF-8
module Kafo
  class ConfigurationException < StandardError
  end

  class ModuleName < StandardError
  end

  class DocParseError < StandardError
  end

  class ConditionError < StandardError
  end
end

class TypeError < StandardError
end
