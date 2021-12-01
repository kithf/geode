# frozen_string_literal: false

module Geode
  module LuaRefinement
    refine String do
      def s    =  "\"#{self}\""
      def to_s =  "\"#{self}\""
    end
  end

  # Creates a Lua abstract syntax tree
  class LuaBuilder
    <<-DOC
    Create a Lua abstract syntax tree

    Usage:

    using Geode::LuaRefinement

    lb = LuaBuilder.new
    lb.fun :dep, "dependency".s
    lb.cond :if, :true { |lb|
      lb.fun :dep, "depif".s
    }

    -->

    root [
      [:f, "dep", "\"dependency\""],
      [:c, "if", :true, block],
    ]

    -->

    dep "dependency"
    if true then
      dep "depif"
    end
    DOC
    def initialize(stamp: "-- Geode::LuaBuilder #{Time.now.getgm}\n", indent: 0, wrap: false)
      @lines = []
      @stamp = stamp || ""
      @indent = indent
      @wrap = wrap
    end

    def call(name, *args, **kwargs)
      @lines.append [:f, name.to_s, args, kwargs.fetch(:brackets, false)]
    end

    def cond(name, condition, &block)
      @lines.append [:c, name.to_s, condition, block]
    end

    def global(name, value)
      @lines.append [:a, name.to_s, value]
    end

    def local(name, value)
      @lines.append [:a, "local #{name}", value]
    end

    def raw(value)
      @lines.append [:b, value]
    end

    def s(value)
      "\"#{value}\""
    end

    def build
      root = @stamp

      if @wrap
        root << "return function(env)\n"
        @indent += 1
      end

      @lines.each do |type, name, val, block|
        case type
        when :f
          args = block ? "(#{val.first})" : " #{val.first}"
          args = "(#{val.join(", ")})" if val.length > 1

          root << "#{" " * @indent}#{name}#{args}\n"
        when :c
          keyword, wrap = conv name

          root << (" " * @indent).to_s
          root << "#{keyword} #{wrap ? "(" : ""}" << val.to_s << "#{wrap ? ")" : ""} then"
          root << "\n"

          local_builder = LuaBuilder.new stamp: false, indent: @indent + 1
          block.call local_builder
          root << local_builder.build

          root << "#{" " * @indent}end\n"
        when :a
          root << "#{" " * @indent}#{name} = #{val}\n"
        when :b
          name.strip.each_line do |line|
            root << "#{" " * @indent}#{line}"
          end
          root << "\n"
        end
      end

      @wrap ? root << "end\n" : root
    end

    private

    def conv(name)
      case name.to_s
      when "if"
        ["if", false]
      when "unless"
        ["if not", true]
      end
    end
  end
end
