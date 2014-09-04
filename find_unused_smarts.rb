require 'fileutils'
require 'yaml'

prefixes = ["single","double","triple","quadruple"]
suffixes = ["count"]

# ARGV == ["file1.txt", "file2.txt"]
# ruby find_unused_smarts.rb *_for_classifier.txt

smarts_file = 'smart_search_strings.yml'

dir = ARGV.first
files = []
files << Dir.glob(File.join(dir, "*_classifier.txt"))
files << Dir.glob(File.join(dir,"**", "*_classifier.txt"))
files << Dir.glob(File.join(dir, "*","*","*_classifier.txt"))
files << Dir.glob(File.join(dir, "*","*","*","_classifier.txt"))
files.flatten!
files.compact!
files.uniq!
files.delete_if {|f| File.zero?(f)}

lines = []
files.map do |file|
  lines << File.readlines(file)
end
line_set = lines.flatten.uniq

key_array = []
YAML.load_file(smarts_file).keys.map do |entry|
	item = entry.to_s
	key_array << item
	key_array << prefixes.map {|pre| [pre, item].join("_") }
	key_array << suffixes.map {|suf| [item, suf].join("_") }
end
key_array.flatten!
key_array.uniq!


used = []
key_array.each do |item|
  r = Regexp.new item
  line_set.each do |line|
    if line[r]
      used << item
      break
    end
  end
end


# puts used
puts key_array - used
