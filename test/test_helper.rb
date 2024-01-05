# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "win32/registry"
require "minitest/autorun"

module RegistryHelper
  private def backslachs(path)
    path.gsub("/", "\\")
  end

  TEST_REGISTRY_KEY = "SOFTWARE/ruby-win32-registry-test/"

  def setup
    Win32::Registry::HKEY_CURRENT_USER.open(backslachs(File.dirname(TEST_REGISTRY_KEY))) do |reg|
      reg.delete_key File.basename(TEST_REGISTRY_KEY), true
    end
  rescue Win32::Registry::Error
  end
end
