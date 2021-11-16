# frozen_string_literal: true

require_relative "file"
require_relative "semver"

module Geode
  class Plugin
    def initialize(**kws)
      @name = kws.fetch(:name, "No Name")
      @description = kws.fetch(:description) { kws.fetch(:desc, "No Description") }
      @version = Geode::Version.new kws.fetch(:version, "0.0.0")
    end
  end
end
