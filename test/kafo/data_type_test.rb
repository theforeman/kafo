require 'test_helper'

module Kafo
  describe DataType do
    describe ".register_type" do
      after { DataType.unregister_type('Example') }
      it { _(DataType.tap { |dt| dt.register_type('Example', 'test') }.types).must_include 'Example' }

      it 'raises error when registered twice' do
        DataType.register_type('Example', 'test')
        _(Proc.new { DataType.register_type('Example', 'different') }).must_raise ArgumentError
      end
    end

    describe ".new_from_string" do
      let(:data_type) do
        dt = Minitest::Mock.new
        dt.expect(:is_a?, false, [String])
        dt
      end
      before do
        DataType.register_type('Example', data_type)
        DataType.register_type('Alias', 'Example')
      end
      after do
        DataType.unregister_type('Example')
        DataType.unregister_type('Alias')
      end

      it 'instantiates type with no arguments' do
        data_type.expect(:new, 'instance', [])
        _(DataType.new_from_string('Example')).must_equal 'instance'
      end

      it 'instantiates alias with no type arguments' do
        data_type.expect(:new, 'instance', [])
        _(DataType.new_from_string('Alias')).must_equal 'instance'
      end

      it 'instantiates type with one argument' do
        data_type.expect(:new, 'instance', ['1'])
        _(DataType.new_from_string('Example[1]')).must_equal 'instance'
      end

      it 'removes quotes from arguments' do
        data_type.expect(:new, 'instance', ['test'])
        _(DataType.new_from_string('Example["test"]')).must_equal 'instance'
      end

      it 'removes single quotes from arguments' do
        data_type.expect(:new, 'instance', ['test'])
        _(DataType.new_from_string("Example['test']")).must_equal 'instance'
      end

      it 'parses empty quotes from arguments' do
        data_type.expect(:new, 'instance', [''])
        _(DataType.new_from_string('Example[""]')).must_equal 'instance'
      end

      it 'instantiates type with multiple arguments' do
        data_type.expect(:new, 'instance', ['1', 'Float', '(regexp)', 'Enum["foo", \'bar\']', '-2'])
        _(DataType.new_from_string('Example[1,Float, /(regexp)/, Enum["foo", \'bar\'],-2]')).must_equal 'instance'
      end

      it 'instantiates type with multiple nested arguments' do
        data_type.expect(:new, 'instance', ['Hash[String, String]', 'Hash[String, String]'])
        _(DataType.new_from_string('Example[Hash[String, String], Hash[String, String]]')).must_equal 'instance'
      end

      it 'instantiates type with multiple nested arguments (2 levels)' do
        data_type.expect(:new, 'instance', ['Hash[Array[String], Array[String]]', 'Hash[Array[String], Array[String]]'])
        _(DataType.new_from_string('Example[Hash[Array[String], Array[String]], Hash[Array[String], Array[String]]]')).must_equal 'instance'
      end

      it 'instantiates type with escaped regexes in arguments' do
        data_type.expect(:new, 'instance', ['https?:\/\/\w+\.com', 'String'])
        _(DataType.new_from_string('Example[/https?:\/\/\w+\.com/, String]')).must_equal 'instance'
      end

      it 'instantiates type with hash arguments' do
        data_type.expect(:new, 'instance', [{'mode' => 'Enum[read, write, update]',
                                             'path' => 'Optional[String[1]]',
                                             'NotUndef[owner]' => 'Optional[String[1]]'}])
        _(DataType.new_from_string('Example[{mode            => Enum[read, write, update],
                                           path            => Optional[String[1]],
                                           NotUndef[owner] => Optional[String[1]]}]')).must_equal 'instance'
      end

      it 'raises error parsing types with mismatched quotes' do
        _(Proc.new { DataType.new_from_string('Example["test]') }).must_raise ConfigurationException
      end

      it 'raises error parsing types with mismatched brackets' do
        _(Proc.new { DataType.new_from_string('Example[Array[String]') }).must_raise ConfigurationException
      end

      it 'raises error parsing types with unknown argument' do
        _(Proc.new { DataType.new_from_string('Example[&]') }).must_raise ConfigurationException
      end

      it 'aliases Data to Any' do
        _(DataType.new_from_string('Data')).must_be_instance_of DataTypes::Any
      end

      it 'aliases Default to Enum' do
        _(DataType.new_from_string('Default')).must_be_instance_of DataTypes::Enum
      end

      it { _(Proc.new { DataType.new_from_string('') }).must_raise ConfigurationException }
      it { _(Proc.new { DataType.new_from_string('Unknown') }).must_raise ConfigurationException }
    end

    describe "#condition_value" do
      it { _(DataType.new.condition_value('foo')).must_equal '"foo"' }
    end

    describe "#dump_default" do
      it { _(DataType.new.dump_default('foo')).must_equal '"foo"' }
    end

    describe "#multivalued?" do
      it { _(DataType.new.multivalued?).must_equal false }
    end

    describe "#to_s" do
      it { _(DataType.new.to_s).must_equal 'datatype' }
    end

    describe "#typecast" do
      it { _(DataType.new.typecast('test')).must_equal 'test' }
      it { _(DataType.new.typecast('UNDEF')).must_be_nil }
    end

    describe "#valid?" do
      it { _(DataType.new.valid?(nil)).must_equal true }
      it { _(DataType.new.valid?(nil, [])).must_equal true }
    end
  end
end
