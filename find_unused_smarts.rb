require 'fileutils'
require 'yaml'

prefixes = ["single","double","triple","quadruple"]
suffixes = ["count"]

# ARGV == ["file1.txt", "file2.txt"]
# ruby find_unused_smarts.rb *_for_classifier.txt

smarts_file = 'smart_search_strings.yml'

dir = ARGV.first
files = []
files << Dir.glob(File.join(dir, "*_for_classifier.txt"))
files << Dir.glob(File.join(dir,"**", "*_for_classifier.txt"))
files << Dir.glob(File.join(dir, "*","*","*_for_classifier.txt"))
files << Dir.glob(File.join(dir, "*","*","*","*_for_classifier.txt"))
files.flatten!
files.compact!
files.uniq!
files.delete_if {|f| File.zero?(f)}

key_array = []
YAML.load_file(smarts_file).keys.map do |entry|
	item = entry.to_s
	key_array << item
	key_array << prefixes.map {|pre| [pre, item].join("_") }
	key_array << suffixes.map {|suf| [item, suf].join("_") }
end
key_array.flatten!

p key_array
