
# Do the editing of the svg with Nokogiri


misclassifieds = File.readlines(ARGV.first).uniq.map(&:chomp)
lmids = File.readlines("all_lmids.txt").uniq.map(&:chomp)
require 'pry'
require 'fileutils'
require 'rubabel'

def to_link(id)
  %Q|<a href="http://www.lipidmaps.org/data/LMSDRecord.php?LMID=#{id}">#{id}</a>|
end

ROOTDIR = File.dirname(ARGV.first)
directory = File.join(ROOTDIR,"comparison")
misclassifieds.each do |line|
  next if line[/LM\w* didn't classify/]
  lmid, weka = line.scan(/(\w*)\s*as\s*(\w*)\?\?\?\?/).first
  FileUtils.mkdir_p directory
  begin
    matches = lmids.select {|a| a[weka]}
  rescue 
    binding.pry
  end

  # Use file directory tree to separate files
  File.open( File.join(directory, "#{lmid}.html"), "w") do |io|
    io.puts <<EOF
<!DOCTYPE html>
  <html>
    <body>
      <h1>REAL: </h1>
EOF
    io.puts "\t\t\t\t#{to_link(lmid)}"
    io.puts "<h1> COMPARISONS: </h1>"
    (matches[0..2] + matches.sample(3)).map do |id|
      io.puts "\t\t\t\t#{to_link(id)}"
    end
  io.puts "  </body>\n</html>"
  end
end
