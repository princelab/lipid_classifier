require 'fileutils'
require 'optparse'

Default = {remove_all: false}
options = Default
p = OptionParser.new do |opts|
  opts.on("-r", "--[no-]remove", "Remove all") do |r|
    options[:remove_all] = r
  end
end

p.parse!(ARGV)
if ARGV.size != 1
  puts p
  exit
end





folder = ARGV.first

files = []
files << Dir.glob(File.join(folder,"*_for_analysis_classifier.txt"))
files << Dir.glob(File.join(folder,"**","*_for_analysis_classifier.txt"))
files << Dir.glob(File.join(folder,"*_for_analysis_for_analysis.arff"))
files << Dir.glob(File.join(folder,"**","*_for_analysis_for_analysis.arff"))
if options[:remove_all]
  files << Dir.glob(File.join(folder,"*_for_analysis.arff"))
  files << Dir.glob(File.join(folder,"**","*_for_analysis.arff"))
  files << Dir.glob(File.join(folder,"*_classifier.arff"))
  files << Dir.glob(File.join(folder,"**","*_classifier.arff"))
end
files.flatten!.uniq!

files.each do |file|
  FileUtils.remove(file)
end


