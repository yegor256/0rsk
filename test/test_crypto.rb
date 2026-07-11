# frozen_string_literal: true

require_relative '../objects/crypto'
require_relative '../objects/urror'
# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'

class Rsk::CryptoTest < Minitest::Test
  def test_roundtrips_plaintext
    crypto = Rsk::Crypto.new('my secret passphrase')
    assert_equal('The risk is too high', crypto.decrypt(crypto.encrypt('The risk is too high')))
  end

  def test_marks_encrypted_value_as_not_plain
    crypto = Rsk::Crypto.new('pass')
    refute(crypto.plain?(crypto.encrypt('data')))
  end

  def test_marks_untouched_value_as_plain
    assert(Rsk::Crypto.new('pass').plain?('plain old text'))
  end

  def test_produces_unique_ciphertext_each_time
    crypto = Rsk::Crypto.new('pass')
    refute_equal(
      crypto.encrypt('same text'), crypto.encrypt('same text'),
      'random salt and IV must make every encryption unique'
    )
  end

  def test_fails_to_decrypt_with_wrong_passphrase
    encrypted = Rsk::Crypto.new('correct').encrypt('secret data')
    assert_raises(Rsk::Urror) { Rsk::Crypto.new('wrong').decrypt(encrypted) }
  end

  def test_fails_to_decrypt_tampered_value
    encrypted = Rsk::Crypto.new('pass').encrypt('secret data')
    tampered = encrypted.sub(/.$/) { |c| c == 'A' ? 'B' : 'A' }
    assert_raises(Rsk::Urror) { Rsk::Crypto.new('pass').decrypt(tampered) }
  end

  def test_fails_to_decrypt_plain_value
    assert_raises(Rsk::Urror) { Rsk::Crypto.new('pass').decrypt('never encrypted') }
  end

  def test_fails_to_decrypt_malformed_value
    assert_raises(Rsk::Urror) { Rsk::Crypto.new('pass').decrypt("#{Rsk::Crypto::PREFIX}garbage") }
  end

  def test_roundtrips_empty_string
    crypto = Rsk::Crypto.new('pass')
    assert_equal('', crypto.decrypt(crypto.encrypt('')))
  end

  def test_roundtrips_unicode_text
    crypto = Rsk::Crypto.new('pass')
    text = '你好, друг! 🔒'
    assert_equal(text, crypto.decrypt(crypto.encrypt(text)))
  end
end
