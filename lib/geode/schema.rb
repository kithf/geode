# frozen_string_literal: true

require_relative "lua"

module Geode
  class Schema
    attr_reader :schema, :last_error

    def initialize(path, wrap: true)
      throw StandardError.new "Type mismatch expected String, got #{path.class}" unless path.is_a? String

      @path = path
      @wrap = wrap

      @schema = {}
      @schema["deps"] = {}

      @last_error = nil
    end

    def preload(state, pack)
      yield state, pack
    end

    def error_handler(msg)
      @last_error = msg
    end

    def error?
      @last_error != nil
    end

    def load(new_path = nil, &block)
      state = Lua.new
      path = new_path || @path

      state.s.function "schema.write", :to_ruby => true  do |key, value|
        @schema[key] = value
      end

      state.s.function "schema.get", :to_ruby => true  do |key|
        @schema.fetch key, false
      end

      state.s.function "schema.dep", :to_ruby => true do |name, ver|
        @schema["deps"][name] = ver || "any"
      end

      state.s.function "_rb_error_handler", :to_ruby => true  do |msg|
        error_handler msg
      end

      if block
        preload state, {
          write: ->(k, v) { @schema[k] = v },
          get: ->(k) { @schema.fetch k, false },
          dep: ->(n ,v) { @schema["deps"][n] = v || "any" }
        }, &block
      end

      state.add_eval '
        enable_schema = function(fn)
          local safe = _G
          local env = setmetatable(_G, {
            __newindex = function(s, k, v)
              schema.write(k, v)
            end,
            __index = function(s, k)
              return schema.get(k) or safe[k]
            end,
          })

          setfenv(fn, env)
          xpcall(fn, _rb_error_handler)
        end

        -- dep "name" "version"
        -- dep "name"
        dep = function(name)
          schema.dep(name)

          return function(ver)
            schema.dep(name, ver)
          end
        end

        dependency = dep
        geode = dep
      '

      state.impl
      state.impl_eval

      state.s.eval "enable_schema(function(env)\n#{path}\nend)"
    end

    def file(&block)
      load File.read(@path), &block
    end
  end
end
