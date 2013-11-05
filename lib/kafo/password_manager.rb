# encoding: UTF-8
require 'securerandom'
require 'digest/sha2'
require 'openssl'
require 'base64'

module Kafo
  class PasswordManager
    # generate a random password of lenght n
    #
    # on ruby >= 1.9 we use builtin method urlsafe_base64, on olders we use our own
    # implementation (inspired by urlsafe_base64)
    #
    # the result may contain A-Z, a-z, 0-9, “-” and “_”. “=”
    def password(n = 32)
      return SecureRandom.urlsafe_base64(n) if SecureRandom.respond_to?(:urlsafe_base64)

      s = [SecureRandom.random_bytes(n)].pack("m*")
      s.delete!("\n")
      s.tr!("+/", "-_")
      s.delete!("=")
      s
    end

    def aes_encrypt(text, passphrase)
      cipher = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
      cipher.encrypt
      cipher.key = Digest::SHA2.hexdigest(passphrase)
      cipher.iv  = Digest::SHA2.hexdigest(passphrase + passphrase)

      encrypted = cipher.update(text)
      encrypted << cipher.final
      Base64.encode64(encrypted)
    end

    def aes_decrypt(text, passphrase)
      cipher = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
      cipher.decrypt
      cipher.key = Digest::SHA2.hexdigest(passphrase)
      cipher.iv  = Digest::SHA2.hexdigest(passphrase + passphrase)

      decrypted = cipher.update(Base64.decode64(text))
      decrypted << cipher.final
      decrypted
    end
  end
end
