class LipidClassifier
  class LipidMaps
    Classification = Struct.new(:name, :category_code, :class_code, :subclass_code, :class_level4_code, :identifier) do 
      def to_compare_classification
        "LM#{category_code}#{'%02d' % class_code.to_i}#{'%02d' % subclass_code.to_i}#{'%02d' % class_level4_code.to_i}????"
      end
    end
    def self.parse_classification_from_lmid(string) # add case fixing, and symbols where possible?
      classification = Classification.new(*[nil, string.scan(/LM(.{2})(.{2})(.{2})(.*)(.{4}$)/)].flatten)
      classification.name = LipidClassifier::CategoryCodeToNameMap[classification.category_code.to_sym]
      classification
    end
  end
end
