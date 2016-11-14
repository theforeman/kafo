module Kafo
  module Params
    # A password paramater is stored encrypted in answer file using AES 256 in CBC mode
    #
    # we use a passphrase that is stored in kafo.yaml for encryption
    # encrypted password is prefixed with $1$ (for historical reasons, no connection to
    # Modular Crypt Format)
    class Password < Param
      def value=(value)
        super
        if @value.nil? || @value.empty?
          @value = password_manager.password
        end
        setup_password if @value.is_a?(::String)
        @value
      end

      def value
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
        @value     = password_manager.aes_decrypt(@value[3..-1], phrase)
      end

      def encrypt
        @encrypted = '$1$' + password_manager.aes_encrypt(@value, phrase)
      end

      def password_manager
        @password_manager ||= PasswordManager.new
      end

      def phrase
        @module.configuration.app[:password]
      end

      def internal_value_to_s(value)
        if value.nil?
          super
        elsif value.empty?
          ''.inspect
        else
          'REDACTED'
        end
      end
    end
  end
end
