Dir.glob(File.join("rule_hash", "*.rb")).map {|rfile| require rfile }


class LipidClassifier
  class Rules
    #helpers
    def self.lambda_smart_match_bool(search_string, match_count)
      lambda {|molecule| molecule.each_match(search_string, uniq: true).size == match_count}
    end
    def self.lambda_smart_match_count(search_string)
      lambda {|molecule| molecule.each_match(search_string, uniq: true).size }
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
    Blocks = {:test => lambda {|molecule| molecule.each_match("c1ccccc1", uniq: true).size > 1}, #BENZENE 
      :single_ester => lambda_smart_match_bool("[#6][CX3](=O)[OX2H0][#6]", 1), 
      :double_ester => lambda_smart_match_bool("[#6][CX3](=O)[OX2H0][#6]", 2), 
      :triple_ester => lambda_smart_match_bool("[#6][CX3](=O)[OX2H0][#6]", 3), 
      :quadruple_ester => lambda_smart_match_bool("[#6][CX3](=O)[OX2H0][#6]", 4)
    }
  end
end


if $0 == __FILE__
  require 'yaml'
  File.open("amino_acids.yml", "w") {|f| f.write YAML.dump LipidClassifier::Rules::AminoAcids}
  File.open("smart_search_strings.yml", "w") {|f| f.write YAML.dump LipidClassifier::Rules::SmartSearchStrings}
end
