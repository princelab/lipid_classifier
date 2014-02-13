require 'fileutils'
require 'pry'

dir = ARGV.first
files = []
files << Dir.glob(File.join(dir, "*_for_analysis.arff"))
files << Dir.glob(File.join(dir,"**", "*_for_analysis.arff"))
files << Dir.glob(File.join(dir, "*","*","*_for_analysis.arff"))
files << Dir.glob(File.join(dir, "*","*","*","*_for_analysis.arff"))
files.flatten!
files.compact!
files.delete_if {|f| File.zero?(f)}

files.each do |file|

  dotfile = file.gsub(File.extname(file), ".dot")
  pdffile = file.gsub(File.extname(file), ".pdf")
  system "java weka.classifiers.trees.J48 -C 0.25 -M 2 -t #{file} -g > #{dotfile}"
  system "dot -Tpdf #{dotfile} -o #{pdffile}"
  FileUtils.rm dotfile
end
