class LipidClassifier
  class LipidMaps
    Classification = Struct.new(:name, :category_code, :class_code, :subclass_code, :class_level4_code, :identifier)
    def self.parse_classification_from_lmid(string) # add case fixing, and symbols where possible?
      classification = Classification.new(*[nil, string.scan(/LM(.{2})(.{2})(.{2})(.*)(.{4}$)/)].flatten)
      classification.name = LipidClassifier::CategoryCodeToNameMap[classification.category_code.to_sym]
      classification
    end
  end
end
