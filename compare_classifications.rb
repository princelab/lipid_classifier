
# Do the editing of the svg with Nokogiri
require 'nokogiri'

  MAXW = 800
  MAXH = 8000
def write_container_svg(main_svg, internal_svgs)
  header = %Q|"<?xml version="1.0"?>\n<svg version="1.1" id="topsvg"\nxmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"\nxmlns:cml="http://www.xml-cml.org/schema" x="0" y="0" width="200px" height="200px" viewBox="0 0 100 100">\n|
  output = ""
  footer = "</svg>\n\n"
  # Process the svgs
  height = 7200.0/internal_svgs.size/2.0
  height = 400 if height > 400
  total_height = 0
  main_svg.gsub(/viewBox="\d* \d* \d* \d*"/,%Q{width="800px" height="800px"}) #resize to 800x800
  # 2 columns down to the end
  
  #Try it in the 1:1 case first
end


misclassifieds = File.readlines("misclassified.txt").uniq.map(&:chomp)
lmids = File.readlines("lmids.txt").uniq.map(&:chomp)
require 'pry'
require 'fileutils'
require 'rubabel'

ROOTDIR = 'lmid_vs_weka'
misclassifieds.each do |line|
  lmid, weka = line.scan(/(\w*)\s*as\s*(\w*)\?\?\?\?/).first
  directory = File.join(ROOTDIR,lmid)
  FileUtils.mkdir_p directory
  matches = lmids.select {|a| a[weka]}
  # Don't bother yet... 
  #p write_container_svg(Rubabel[lmid,:lmid], [Rubabel[matches.first,:lmid]])

  # Use file directory tree to separate files
  Rubabel[lmid, :lmid].write_file(File.join(directory,"real.svg"))
  matches[0..5].map.with_index do |id, i|
    Rubabel[id, :lmid].write_file(File.join(directory,"#{id}_#{i}.svg"))
  end

end
