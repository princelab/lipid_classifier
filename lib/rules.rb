$:.unshift(File.dirname(__FILE__))
require 'lipid_classifier'
Dir.glob(File.join("rules", "*.rb")).map {|rfile| require rfile }

NumberNames = {1 =>  "single", 2 =>  "double", 3 =>  "triple", 4 =>  "quadruple"}
class LipidClassifier
  class Rules    
    AminoAcids = {
    }
    SMARTS = {
      ester: "[#6][CX3](=O)[OX2H0][#6]", 
      ketone: "[#6][CX3](=O)[#6]", 
      ether: "[OD2]([#6])[#6]", 
      amide: "[NX3][CX3](=[OX1])[#6]",
      vinylic_carbon: "[$([CX3]=[CX3])]",
      proton: "[H+]",
    } # MERGE the amino_acid components together, then add them to this thing (complete, and X_side_chain)
    #helpers
    def self.lambda_smart_match_bool(search_string, match_count = 1)
      lambda {|molecule| molecule.each_match(search_string, uniq: true).size > (match_count - 1)}
    end
    def self.lambda_smart_match_bool_by_count(search_string, match_count = 1)
      lambda {|molecule| molecule.each_match(search_string, uniq: true).size == match_count}
    end
    def self.lambda_smart_match_count(search_string)
      lambda {|molecule| molecule.each_match(search_string, uniq: true).size }
    end
    def self.method_add_to_hash_from_smarts_and_count(hash, smart_key, number)
      new_key = [NumberNames[number], smart_key.to_s].join("_")
      hash[new_key.to_sym] = lambda_smart_match_bool_by_count(SMARTS[smart_key], number)
    end
    AminoAcids = {
    }
    SmartSearchStrings = {
      ester: "[#6][CX3](=O)[OX2H0][#6]", 
      ketone: "[#6][CX3](=O)[#6]", 
      ether: "[OD2]([#6])[#6]", 
      amide: "[NX3][CX3](=[OX1])[#6]",
      vinylic_carbon: "[$([CX3]=[CX3])]",
      proton: "[H+]",
    } # MERGE the amino_acid components together, then add them to this thing (complete, and X_side_chain)
    # BOOLEAN responses, or numbers
    Blocks = {:test => lambda {|molecule| molecule.each_match("c1ccccc1", uniq: true).to_a.size > 0}, #BENZENE 
      #:single_ester => lambda_smart_match_bool_by_count("[#6][CX3](=O)[OX2H0][#6]", 1), 
      #:double_ester => lambda_smart_match_bool_by_count("[#6][CX3](=O)[OX2H0][#6]", 2), 
      #:triple_ester => lambda_smart_match_bool_by_count("[#6][CX3](=O)[OX2H0][#6]", 3), 
      #:quadruple_ester => lambda_smart_match_bool_by_count("[#6][CX3](=O)[OX2H0][#6]", 4),
      :ester_count => lambda_smart_match_count("[#6][CX3](=O)[OX2H0][#6]")
    }
    (1..4).to_a.map {|i| method_add_to_hash_from_smarts_and_count(Blocks, :ester, i) }
  end
end

# Generate rules for all the SMARTS


if $0 == __FILE__
  mol = Rubabel["C1=CC=CC=C1"]
  p LipidClassifier::Rules::Blocks
  puts "Should be true: #{LipidClassifier::Rules::Blocks[:test].call Rubabel["C1=CC=CC=C1"]}"
  puts "ARE YOU SURE? You'll have to comment out the code to run these..."
  #File.open("amino_acids.yml", "w") {|f| f.write YAML.dump LipidClassifier::Rules::AminoAcids}
  #File.open("smart_search_strings.yml", "w") {|f| f.write YAML.dump LipidClassifier::Rules::SmartSearchStrings}
end
