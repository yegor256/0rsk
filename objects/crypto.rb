# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'base64'
require 'openssl'
require 'securerandom'
require_relative 'rsk'
require_relative 'urror'

class Rsk::Crypto
  PREFIX = '$aes-256-gcm$'
  ITERATIONS = 200_000

  def initialize(passphrase)
    @passphrase = passphrase
  end

  def encrypt(plaintext)
    salt = SecureRandom.random_bytes(16)
    cipher = OpenSSL::Cipher.new('aes-256-gcm')
    cipher.encrypt
    cipher.key = key(salt)
    # rubocop:disable Elegant/NoRedundantVariable
    iv = cipher.random_iv
    ciphertext = cipher.update(plaintext) + cipher.final
    # rubocop:enable Elegant/NoRedundantVariable
    [
      Rsk::Crypto::PREFIX,
      Base64.strict_encode64(salt), ':',
      Base64.strict_encode64(iv), ':',
      Base64.strict_encode64(ciphertext), ':',
      Base64.strict_encode64(cipher.auth_tag)
    ].join
  end

  def decrypt(encrypted)
    raise(Rsk::Urror, 'Not an encrypted value') unless plain?(encrypted).eql?(false)
    salt, iv, ciphertext, tag = encrypted.delete_prefix(Rsk::Crypto::PREFIX).split(':', 4)
    raise(Rsk::Urror, 'Malformed encrypted value') if tag.nil?
    cipher = OpenSSL::Cipher.new('aes-256-gcm')
    cipher.decrypt
    begin
      cipher.key = key(Base64.strict_decode64(salt))
      cipher.iv = Base64.strict_decode64(iv)
      cipher.auth_tag = Base64.strict_decode64(tag)
      (cipher.update(Base64.strict_decode64(ciphertext)) + cipher.final).force_encoding('UTF-8')
    rescue OpenSSL::Cipher::CipherError, ArgumentError => e
      raise(Rsk::Urror, "Can't decrypt, wrong passphrase or corrupted value: #{e.message}")
    end
  end

  def plain?(text)
    !text.start_with?(Rsk::Crypto::PREFIX)
  end

  private

  def key(salt)
    OpenSSL::PKCS5.pbkdf2_hmac(@passphrase, salt, Rsk::Crypto::ITERATIONS, 32, 'sha256')
  end
end
