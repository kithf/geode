# frozen_string_literal: true

require "git"
require "uri"
require "open-uri"
require "zip"
require "fileutils"

OFile = File

def download_method(str)
  case OFile.extname(URI(str).path)
  when ".git"
    "git"
  when ".zip"
    "zip"
  when "git"
    "git"
  else
    return "git" if str.include?("github") || str.include?("gitlab")

    "web"
  end
end

module Geode
  module File
    def self.download(url, file_name = false, **kws)
      path = kws.fetch :path, "./"
      ofile = !file_name
      file_name ||= URI(url).path.match(%r{[^/\\]+$}).to_s
      file = OFile.join(path, file_name)

      case download_method url
      when "zip"
        zip_path = "#{path}/#{+OFile.basename(file, OFile.extname(file))}"
        FileUtils.mkpath zip_path unless OFile.exists? zip_path
        Zip::File.open_buffer open(url) do |zip|
          zip.each do |e|
            epath = OFile.join zip_path, e.name
            e.extract epath unless OFile.exists? epath
          end
        end
        OFile.rename zip_path.to_s, "#{path}/#{+OFile.basename(file, ".zip")}" unless ofile
      when "web"
        FileUtils.mkpath path unless OFile.exists? path
        open file.to_s, "w" do |of|
          IO.copy_stream URI.open(url.strip), of
        end
      when "git"
        Git.clone url, OFile.basename(file, ".git"), recursive: true, **kws
      end
    end
  end
end
