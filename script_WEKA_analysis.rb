
def grab_arffs(directory)
  files = Dir.glob(File.join(directory, "*","**","*.arff"))
  files.each do |file|
    run_weka_on_arff_file(file)
  end
end



if $0 == __FILE__
  grab_arffs ARGV.first


end
