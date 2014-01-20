$:.unshift(File.join(File.dirname(__FILE__), ".."))
require 'lipid_classifier'


class LipidClassifier
  class Rules
    FunctionalGroups.merge! RawSmarts
  end
end

if __FILE__ == $0
  p LipidClassifier::Rules::FunctionalGroups.first
  puts LipidClassifier::Rules::FunctionalGroups

end
