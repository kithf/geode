require_relative "../lib/geode/schema"
require "pp"

sc = Geode::Schema.new '
name = "Example"
desc = "Example manifest"
arch = "x86"

if os.arch() == "x64" then
  arch = "x64"
end

for i = 1, 5 do
  schema.write("var"..i, i)
end
'
sc.load
pp sc.error? ? sc.last_error : sc.schema