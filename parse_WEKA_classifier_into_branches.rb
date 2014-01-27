LogicRow = Struct.new(:layer, :level, :parameter, :logic_operator, :number, :assignment, :correct_count, :wrong_count)



# PARSE a file
lines = File.readlines("category_classifier_from_WEKA.txt")


# Test lines
testlines = ["phenyl_count <= 1", "|   single_phosphate <= 0", "|   |   sphingosine <= 0", "|   |   |   double_phosphoric_ester_groups <= 0", "|   |   |   |   single_glycerol <= 0","|   |   |   |   |   four_carbon_saturated_FA <= 0","|   |   |   |   |   |   unsaturated_fatty_acid_unit_count <= 3","|   |   |   |   |   |   |   single_alanine <= 0","|   |   |   |   |   |   |   |   not_hydrogen_count <= 9: FA (65.0/2.0)","|   |   |   |   |   |   |   |   not_hydrogen_count > 9","|   |   |   |   |   |   |   |   |   alanine <= 0: FA (14.0)}"]

# level can be category, class, subclass, level4_class
def line_filter(line, level)
  layer = line.count "|"
  arr = line.scan(/\s*+(\w*) ([<>=]*) (\d*)/)
  parameter, logic_operator, number = line.scan(/\|\s*+(\w*) ([<>=]*) (\d*)/)
  arr2 = line.scan(/: ([A-Z]*) \((\d*.\d*)\/(\d*.\d*)\)/)
  arr2 = line.scan(/: ([A-Z]*) \((\d*.\d*)\)/) if arr2.empty?
  LogicRow.new(*[layer, level, arr, arr2].flatten)
end

extracted_lines = testlines.map {|a| p line_filter(a.chomp, "category")}

def write_lines_to_code(rows, filename = "WEKA_classifier.rb")
  to_file = [] 
    # Introductory code goes here
    curr_layer = 0
    rows.map do |row|
      while curr_layer > row.layer
        to_file << "#{"\t"*curr_layer}end"
        curr_layer -= 1
      end
      curr_layer = row.layer
      to_file << "#{"\t"*row.layer}if hash.#{row.parameter} #{row.logic_operator} #{row.number}"
      if row.assignment
        to_file << "#{"\t"*(row.layer+1)}assignment.#{row.level} = #{row.assignment}"
        to_file << "#{"\t"*(row.layer)}end"
      end
    end # rows.map
    while curr_layer > 0
      to_file << "#{"\t"*(curr_layer-1)}end"
      curr_layer -= 1
    end
 File.open(filename, 'w') do |fileio|
   fileio.puts to_file
 end
end

write_lines_to_code extracted_lines





