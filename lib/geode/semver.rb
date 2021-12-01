# frozen_string_literal: true

# deps:
#   - package => 1.0
module Geode
  class Version < Gem::Version
    def initialize(ver)
      super process(ver)
    end

    def create(ver)
      super process(ver)
    end

    def latest(vers, **kws)
      release = kws.fetch :release, false
      version = kws.fetch :version, create(@version)
      last = false

      vers.each do |v|
        v = create v unless v.is_a? Geode::Version
        next if version >= v
        next unless !last || (last < v)

        last = v unless release ? v.prerelease? : false
      end
      last
    end

    private

    def process(ver)
      ver = ver.join "." if ver.is_a? Array
      if ver.is_a? Hash
        ver = ver
              .select { |k, _v| %w[major minor build pre].include? k.to_s }
              .update({ major: 0, minor: 0, build: 0, pre: nil }) { |_k, v, _nv| v }
              .sort_by do |k, v|
                case k
                when :major, "major"
                  0
                when :minor, "minor"
                  1
                when :build, "build"
                  2
                when :pre, "pre"
                  3
                else
                  v
                end
              end
              .to_h
              .compact
              .map    { |_k, v| v }
              .join   "."
      end
      ver
    end
  end
end
