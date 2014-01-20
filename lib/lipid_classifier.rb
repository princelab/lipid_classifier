require 'rubabel'
require 'pry'
require 'yaml'

Dir.glob(File.dirname(__FILE__) + "*.rb").map {|f| require f }

class LipidClassifier
  # Load the SMARTS into RULES
  class Rules
    RawSmarts = YAML.load_file("smart_search_strings.yml")
    AAs = YAML.load_file("amino_acids.yml")
    Smarts = {}
    FunctionalGroups = {}
    AminoAcids = {}
  end
end
