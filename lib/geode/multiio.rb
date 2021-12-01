# frozen_string_literal: true

module Geode
  class MultiIO
    def initialize(*targets)
      @targets = targets
    end

    def write(*args)
      @targets.each { |t| t.write(*args) }
    end

    def close
      @targets.each { |t| t.close if t.instance_of? File }
    end
  end
end
