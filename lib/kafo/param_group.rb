#encoding: UTF-8
class ParamGroup
  attr_reader :children, :params, :name
  attr_accessor :module

  def initialize(name)
    @children = []
    @params = []
    @name = name
  end

  def formatted_name
    @formatted_name ||= @name[-1] == ':' ? @name.chop : @name
  end

  def add_child(group)
    @children.push group unless @children.include?(group)
  end

  def add_param(param)
    @params.push param unless @params.include?(param)
  end
end
