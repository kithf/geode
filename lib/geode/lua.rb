# frozen_string_literal: true

require "rufus-lua-win" if Gem.win_platform?
require "rufus-lua"

FUNS = [].freeze

class Lua
  attr_reader :s

  def initialize
    @no_load = []
    @s = Rufus::Lua::State.new
  end

  def self.add(name, &body)
    FUNS.append [name.to_s, body]
  end

  def self.rem(name)
    FUNS.each do |f|
      FUNS.delete f if f[0] == name.to_s
    end
  end

  def no_load(*funs)
    @no_load = funs.map(&:to_s)
  end

  def impl
    FUNS.each do |name, body|
      @s.function name, &body unless @no_load.include? name
    end
  end

  def close
    @s.close
  end
end

#
# test "123" --> Testing: 123
# test() --> Testing: Test
#
Lua.add :test do |d = "Test"|
  puts "Testing: #{d}"
end
