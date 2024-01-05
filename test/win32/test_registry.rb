# frozen_string_literal: true

require "test_helper"

class Win32::TestRegistry < Minitest::Test
  include RegistryHelper

  def test_open_no_block
    Win32::Registry::HKEY_CURRENT_USER.create(backslachs(TEST_REGISTRY_KEY)).close

    reg = Win32::Registry::HKEY_CURRENT_USER.open(backslachs(TEST_REGISTRY_KEY), Win32::Registry::KEY_ALL_ACCESS)
    assert_kind_of Win32::Registry, reg
    assert_equal true, reg.open?
    assert_equal false, reg.created?
    reg["test"] = "abc"
    reg.close
    assert_raises(Win32::Registry::Error) do
      reg["test"] = "abc"
    end
  end

  def test_open_with_block
    Win32::Registry::HKEY_CURRENT_USER.create(backslachs(TEST_REGISTRY_KEY)).close

    regs = []
    Win32::Registry::HKEY_CURRENT_USER.open(backslachs(TEST_REGISTRY_KEY), Win32::Registry::KEY_ALL_ACCESS) do |reg|
      regs << reg
      assert_equal true, reg.open?
      assert_equal false, reg.created?
      reg["test"] = "abc"
    end

    assert_equal 1, regs.size
    assert_kind_of Win32::Registry, regs[0]
    assert_raises(Win32::Registry::Error) do
      regs[0]["test"] = "abc"
    end
  end

  def test_create_no_block
    reg = Win32::Registry::HKEY_CURRENT_USER.create(backslachs(TEST_REGISTRY_KEY))
    assert_kind_of Win32::Registry, reg
    assert_equal true, reg.open?
    assert_equal true, reg.created?
    reg["test"] = "abc"
    reg.close
    assert_equal false, reg.open?
    assert_raises(Win32::Registry::Error) do
      reg["test"] = "abc"
    end
  end

  def test_create_with_block
    regs = []
    Win32::Registry::HKEY_CURRENT_USER.create(backslachs(TEST_REGISTRY_KEY)) do |reg|
      regs << reg
      reg["test"] = "abc"
      assert_equal true, reg.open?
      assert_equal true, reg.created?
    end

    assert_equal 1, regs.size
    assert_kind_of Win32::Registry, regs[0]
    assert_equal false, regs[0].open?
    assert_raises(Win32::Registry::Error) do
      regs[0]["test"] = "abc"
    end
  end

  def test_accessors
    Win32::Registry::HKEY_CURRENT_USER.create(backslachs(TEST_REGISTRY_KEY)) do |reg|
      assert_kind_of Integer, reg.hkey
      assert_kind_of Win32::Registry, reg.parent
      assert_equal "HKEY_CURRENT_USER", reg.parent.name
      assert_equal "SOFTWARE\\ruby-win32-registry-test\\", reg.keyname
      assert_equal Win32::Registry::REG_CREATED_NEW_KEY, reg.disposition
    end
  end

  def test_name
    Win32::Registry::HKEY_CURRENT_USER.create(backslachs(TEST_REGISTRY_KEY)) do |reg|
      assert_equal "HKEY_CURRENT_USER\\SOFTWARE\\ruby-win32-registry-test\\", reg.name
    end
  end

  def test_keys
    Win32::Registry::HKEY_CURRENT_USER.create(backslachs(TEST_REGISTRY_KEY)) do |reg|
      reg.create("key1")
      assert_equal ["key1"], reg.keys
    end
  end

  def test_each_key
    keys = []
    Win32::Registry::HKEY_CURRENT_USER.create(backslachs(TEST_REGISTRY_KEY)) do |reg|
      reg.create("key1")
      reg.each_key { |*a| keys << a }
    end
    assert_equal [2], keys.map(&:size)
    assert_equal ["key1"], keys.map(&:first)
    assert_in_delta Win32::Registry.time2wtime(Time.now), keys[0][1], 10_000_000_000, "wtime should roughly match Time.now"
  end

  def test_values
    Win32::Registry::HKEY_CURRENT_USER.create(backslachs(TEST_REGISTRY_KEY)) do |reg|
      reg.create("key1")
      reg["value1"] = "abcd"
      assert_equal ["abcd"], reg.values
    end
  end

  def test_each_value
    vals = []
    Win32::Registry::HKEY_CURRENT_USER.create(backslachs(TEST_REGISTRY_KEY)) do |reg|
      reg.create("key1")
      reg["value1"] = "abcd"
      reg.each_value { |*a| vals << a }
    end
    assert_equal [["value1", Win32::Registry::REG_SZ, "abcd"]], vals
  end

  def test_utf8_encoding
    keys = []
    Win32::Registry::HKEY_CURRENT_USER.create(backslachs(TEST_REGISTRY_KEY)) do |reg|
      reg.create("abc EUR")
      reg.create("abc €")
      reg.each_key do |subkey|
        keys << subkey
      end
    end

    assert_equal [Encoding::UTF_8] * 2, keys.map(&:encoding)
    assert_equal ["abc EUR", "abc €"], keys
  end

end
