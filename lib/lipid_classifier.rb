require 'bundler/setup'
require 'rubabel'
require 'yaml'

Dir.glob(File.dirname(__FILE__) + "*.rb").map {|f| require f }

# Library requires
require 'weka'
require 'lipidmaps'

def putsv(thing)
  puts thing if LCVERBOSE
end

class LipidClassifier
  CategoryCodeToNameMap = {:FA=>"Fatty Acyls", :GL=>"Glycerolipids", :GP=>"Glycerophospholipids", :SP=>"Sphingolipids", :ST=>"Sterol Lipids", :PR=>"Prenol Lipids", :SL=>"Saccharolipids", :PK=>"Polyketides"}
  Classification = Struct.new(:name, :category_code, :class_code, :subclass_code, :class_level4_code, :identifier)
  def self.parse_classification_from_LMID(string) # add case fixing, and symbols where possible?
    key = string.to_sym
    load_corrections unless @corrections
    corrected = @corrections[key]
    if corrected
      classification = Classification.new(*[nil, corrected.scan(/LM(.{2})(.{2})(.{2})(.*)(.{4}$)/)].flatten)
      p "corrected a classification!"
    else
      classification = Classification.new(*[nil, string.scan(/LM(.{2})(.{2})(.{2})(.*)(.{4}$)/)].flatten)
    end
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
  def self.load_corrections
    file = File.join(__dir__, "..", 'corrections.yml')
    @corrections = YAML.load_file(file)
  end
end



require 'rules'
