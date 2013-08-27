require File.join(File.dirname(__FILE__), '../../../../../../lib/kafo/password_manager')
# Decrypts an encrypted password using $kafo_configure::password
#
# you can use this function in order to place passwords into your config files
# in form of a plain text
module Puppet::Parser::Functions
  newfunction(:decrypt, :type => :rvalue) do |args|
    encrypted = args[0]
    if encrypted =~ /\A\$1\$/
      PasswordManager.new.aes_decrypt(encrypted[3..-1], lookupvar('::kafo_configure::password'))
    else
      raise Puppet::ParseError, 'wrong format of encrypted string, should start with $1$'
    end
  end
end

