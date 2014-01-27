if hash.phenyl_count <= 1
	if hash.single_phosphate <= 0
		if hash.sphingosine <= 0
			if hash.double_phosphoric_ester_groups <= 0
				if hash.single_glycerol <= 0
					if hash.four_carbon_saturated_FA <= 0
						if hash.unsaturated_fatty_acid_unit_count <= 3
							if hash.single_alanine <= 0
								if hash.not_hydrogen_count <= 9
									assignment.category = FA
								end
								if hash.not_hydrogen_count > 9
									if hash.alanine <= 0
										assignment.category = FA
									end
								end
							end
						end
					end
				end
			end
		end
	end
end
