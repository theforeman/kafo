require 'test_helper'

module Kafo
  describe Params::Password do

    let :dummy_module do
      PuppetModule.new('dummy', nil)
    end

    def decrypt(value)
      PasswordManager.new.aes_decrypt(value, KafoConfigure.config.app[:password])
    end

    describe "non-empty password" do

      subject do
        Params::Password.new(dummy_module, "password").tap do |param|
          param.value = "secret"
        end
      end

      it 'encrypts the value' do
        subject.value.wont_equal 'secret'
      end

      it 'is able to decrypt the value' do
        decrypted_value = decrypt(subject.value[3..-1])
        decrypted_value.must_equal 'secret'
      end

    end

    describe "empty password" do

      subject do
        Params::Password.new(dummy_module, "password").tap do |param|
          param.value = ""
        end
      end

      it 'generates random password' do
        decrypted_value = decrypt(subject.value[3..-1])
        decrypted_value.size.must_be :>, 0
      end

    end

  end
end
