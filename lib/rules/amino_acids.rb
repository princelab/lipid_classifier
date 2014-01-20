$:.unshift(File.join(File.dirname(__FILE__), ".."))
require 'lipid_classifier'

class LipidClassifier
  class Rules
    AminoAcids = {}
    aa_side_chains = AAs[:side_chains]
    AminoAcids.merge! AAs[:amino_acids]
    aa_match = AAs[:generic_amino_acid]
    aa_side_chains.each do |side_chain|
      AminoAcids[side_chain.first.to_s.gsub("_side_chain","").to_sym] = [aa_match, side_chain[1..-1]].flatten 
    end

  end
end

if __FILE__ == $0
  p LipidClassifier::Rules::AminoAcids.first
  puts LipidClassifier::Rules::AminoAcids

end
