module StringHelper
  def dashize(string)
    string.tr('_', '-')
  end
  alias :d :dashize

  def underscore(string)
    string.tr('-', '_')
  end
  alias :u :underscore

  def with_prefix(param)
    "#{d(param.module_name)}-#{d(param.name)}"
  end

  def parametrize(param)
    "--#{with_prefix(param)}"
  end
end
