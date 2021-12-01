# frozen_string_literal: true

require "rufus/lua/win" if Gem.win_platform?
require "rufus/lua"

FUNS = []
EVAL = []

class Lua
  attr_reader :s

  def initialize
    @funs = FUNS
    @eval = EVAL
    @no_load = []
    @s = Rufus::Lua::State.new
    @last_error = nil

    @s.set_error_handler do |msg|
      @last_error = msg
      msg
    end
  end

  def self.add(name, &body)
    FUNS.append [name.to_s, body]
  end

  def self.add_eval(block)
    EVAL.append block
  end

  def add(name, &body)
    @funs.append [name.to_s, body]
  end

  def add_eval(block)
    @eval.append block
  end

  def alias(name, aliases)
    body = false
    @funs.each do |f|
      body = f[1] if f[0] == name.to_s
    end

    return unless body

    aliases.each do |name|
      @funs.append [name.to_s, body]
    end
  end

  def rem(name)
    @funs.each do |f|
      @funs.delete f if f[0] == name.to_s
    end
  end

  def no_load(*funs)
    @no_load = funs.map(&:to_s)
  end

  def impl
    @funs.each do |name, body|
      @s.function name, :to_ruby => true, &body unless @no_load.include? name
    end
  end

  def impl_eval
    @eval.each do |block|
      @s.eval block
    end
  end

  def eval(str)
    @s.eval str
  end

  def close
    @s.close
  end

  def error
    @last_error
  end
end

Lua.add "os.name" do
  Gem::Platform.local.os
end

Lua.add "os.arch" do
  Gem::Platform.local.cpu
end

Lua.add "os.pwd" do
  Dir.pwd
end

Lua.add "io.expand" do |file = ""|
  File.expand_path file
end
