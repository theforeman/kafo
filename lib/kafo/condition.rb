# encoding: UTF-8
class Condition
  VARIABLE_RE = /(\$\w+)/

  def initialize(expression, context = [])
    @expression = expression
    @context = context
  end

  def evaluate
    !!eval(substitute(@expression))
  end

  private

  def substitute(expression)
    expression.gsub(VARIABLE_RE) do |variable|
      param = @context.detect { |p| p.name == $1.tr('$','') }
      raise ConditionError, "can't substitute #{$1}, unknown parameter with such name" if param.nil?
      variable.gsub!($1, param.condition_value)
    end
  end
end
