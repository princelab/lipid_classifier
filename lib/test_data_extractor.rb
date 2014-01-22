require 'mechanize'
require 'pry'



TrainingSetNode = Struct.new(:lmid, :href, :classification) 

CategoryCodeToNameMap = {:FA=>"Fatty Acyls", :GL=>"Glycerolipids", :GP=>"Glycerophospholipids", :SP=>"Sphingolipids", :ST=>"Sterol Lipids", :PR=>"Prenol Lipids", :SL=>"Saccharolipids", :PK=>"Polyketides"}
SubcategoryCodeToNameMap = {}
agent = Mechanize.new

root_page = agent.get("http://www.lipidmaps.org/data/classification/LM_classification_exp.php")
#categories = root_page.search('h2').map {|a| arr = a.text.scan(/(.*)\s\[(\w*)\]/).first; CategoryCodeToNameMap[arr.last.to_sym] = arr.first }

Classification = Struct.new(:name, :category_code, :class_code, :subclass_code, :class_level4_code, :identifier)
def parse_classification_from_LMID(string) # add case fixing, and symbols where possible?
  classification = Classification.new(*[nil, string.scan(/LM(.{2})(.{2})(.{2})(.*)(.{4}$)/)].flatten)
  classification.name = CategoryCodeToNameMap[classification.category_code.to_sym]
  classification
end


links_to_parse = {}
parsed_links = []
root_page.links_with(:href => /\/data\/structure\/LMSDSearch.php/).map do |link|
   links_to_parse[link.text] = [link.href]
   category_page = agent.get(link.href)
   #Nokogiri::HTML(category_page.body).xpath("//table[@datatable]/tbody/tr/").map do |row|
   category_page.links_with(:href => /LMSDRecord.php\?LMID=LM\w{2}\d{8,10}/).map do |clink|
     parsed_links << TrainingSetNode.new(clink.text, clink.href, parse_classification_from_LMID(clink.text) )
   end
end

p parsed_links
#p links_to_parse







if $0 == __FILE__
  require 'yaml'
  parse_classification_from_LMID("LMFA02011999")
  
  #Write the output
  File.open("trainingset.yml", "w") do |outputstream|
    File.open("trainingset_structs.yml", "w") do |outputstream2|
      outputstream2.puts YAML.dump parsed_links
    end
    outputstream.puts YAML.dump parsed_links.map(&:to_h)
  end
end
