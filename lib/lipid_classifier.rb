require 'rubabel'
require 'pry'
require 'yaml'

Dir.glob("lib/**/*.rb").map {|f| require f.gsub(".rb", "") }
def putsv(thing)
  puts thing if LCVERBOSE
end

class LipidClassifier
  CategoryCodeToNameMap = {:FA=>"Fatty Acyls", :GL=>"Glycerolipids", :GP=>"Glycerophospholipids", :SP=>"Sphingolipids", :ST=>"Sterol Lipids", :PR=>"Prenol Lipids", :SL=>"Saccharolipids", :PK=>"Polyketides"}
  Classification = Struct.new(:name, :category_code, :class_code, :subclass_code, :class_level4_code, :identifier)
  def self.parse_classification_from_LMID(string) # add case fixing, and symbols where possible?
    classification = Classification.new(*[nil, string.scan(/LM(.{2})(.{2})(.{2})(.*)(.{4}$)/)].flatten)
    classification.name = CategoryCodeToNameMap[classification.category_code.to_sym]
    classification
  end
  # Load the SMARTS into RULES
  class Rules
    RawSmarts = YAML.load_file("smart_search_strings.yml")
    AAs = YAML.load_file("amino_acids.yml")
    Smarts = {}
    FunctionalGroups = {}
    AminoAcids = {}
  end
end



require 'rules'
