module Params
  # A password paramater is stored encrypted in answer file using AES 256 in CBC mode
  #
  # we use a passphrase that is stored in kafo.yaml for encryption
  # encrypted password is prefixed with $1$ (for historical reasons, no connection to
  # Modular Crypt Format)
  class Password < Param
    def value=(value)
      super
      setup_password if @value.is_a?(::String)
      @value
    end

    # if value was not specified and default is nil we generate a random password
    # also we make sure that we have encrypted version that is to be outputted
    def value
      @value = @value_set ? @value : (default || password_manager.password)
      encrypt if @value.is_a?(::String)
      @encrypted
    end

    private

    def setup_password
      encrypted? ? decrypt : encrypt
    end

    def encrypted?
      @value.length > 3 && @value[0..2] == '$1$'
    end

    def decrypt
      @encrypted = @value
      @value = password_manager.aes_decrypt(@value[3..-1], phrase)
    end

    def encrypt
      @encrypted = '$1$' + password_manager.aes_encrypt(@value, phrase)
    end

    def password_manager
      @password_manager ||= PasswordManager.new
    end

    def phrase
      Configuration::KAFO[:password]
    end

  end
end
