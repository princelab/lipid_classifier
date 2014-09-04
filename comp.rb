classify = lambda do |molecule_hash|
  Assignment = Struct.new(:category, :class, :subclass, :class_level4) do 
    def to_s
      "LM#{@category.to_s}#{@class}#{@subclass}#{@class_level4}"
    end
  end
  assignment = Assignment.new
  # pregenerated
  if hash[:phenyl_count].first <= 1
    if hash[:single_phosphate].first == false
      if hash[:sphingosine].first == false
        if hash[:double_phosphoric_ester_groups].first == false
          if hash[:single_glycerol].first == false
            if hash[:four_carbon_saturated_FA].first == false
              if hash[:unsaturated_fatty_acid_unit_count].first <= 3
                if hash[:single_alanine].first == false
                  if hash[:not_hydrogen_count].first <= 9
                    assignment.category = :FA
                  end
                  if hash[:not_hydrogen_count].first > 9
                    if hash[:alanine].first == false
                      assignment.category = :FA
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end #END pregenerated
  assignment.to_s
end #hash
