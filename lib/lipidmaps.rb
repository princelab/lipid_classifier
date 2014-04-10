require_relative 'lipid_classifier'
require_relative 'utilities/hash.rb'

class LipidClassifier
  class LipidMaps
    Classification = Struct.new(:name, :category_code, :class_code, :subclass_code, :class_level4_code, :identifier) do 
      def to_compare_classification
        "LM#{category_code}#{'%02d' % class_code.to_i}#{'%02d' % subclass_code.to_i}#{'%02d' % class_level4_code.to_i}????"
      end
    end
    def self.parse_classification_from_LMID(string) # add case fixing, and symbols where possible?
      LipidClassifier.load_corrections unless LipidClassifier.corrections
      keys = LipidClassifier.corrections.find_keys(string)
      p keys
      raise ArgumentError if keys.size > 1
      corrected = LipidClassifier.corrections[keys.first]
      if corrected
        if string.size > corrected.size
          corrected = corrected + string[(corrected.size)..-1]
        elsif string.size != corrected.size
          raise ArgumentError
        end
        classification = Classification.new(*[nil, corrected.scan(/LM(.{2})(.{2})(.{2})(.*)(.{4}$)/)].flatten)
        p "corrected a classification!"
      else
        classification = Classification.new(*[nil, string.scan(/LM(.{2})(.{2})(.{2})(.*)(.{4}$)/)].flatten)
      end
      classification.name = CategoryCodeToNameMap[classification.category_code.to_sym]
      classification
    end
  end
end


if __FILE__ == $0
  LipidClassifier.load_corrections
  hash = LipidClassifier.corrections
  key = "LMSP0505DA99"

  p LipidClassifier::LipidMaps.parse_classification_from_LMID(key)
end
