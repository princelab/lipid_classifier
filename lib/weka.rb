DEBUG = true
class LipidClassifier
  class WEKA
    def self.bind_into_class 
      binding
    end
    TOFILE = false
    LogicRow = Struct.new(:layer, :level, :parameter, :logic_operator, :number, :assignment, :correct_count, :wrong_count)
    Assignment = Struct.new(:category, :class, :subclass, :class_level4) do 
      def to_s
        "LM#{@category.to_s}#{@class}#{@subclass}#{@class_level4}"
      end
    end

    Categories = %w{FA GL ST PR SL PK SP GP}
    def self.determine_current_level_by_filestructure(files_match)
      # files_match should start with a category
      file_levels = files_match.split(/(\\|\/)/)

    end

    def self.load_classifications(directory)
      files = Dir.glob(directory + "/**/*.arff").map{|a| a.sub(directory + '/','') }
      @classifiers = {}
    end

    def self.identify_lipid(lmid)
      load_classifications unless @classifiers

    end
    def self.read_file_for_lines(file)
      # level can be category, class, subclass, level4_class
      level = determine_current_level_by_filestructure(file)
      File.readlines(file).map {|line| line_filter(line, level)}
    end

    # level can be category, class, subclass, level4_class
    def self.line_filter(line, level)
      layer = line.count "|"
      arr = line.scan(/\s*+(\w*) ([<>=]*) (\d*)/)
      parameter, logic_operator, number = line.scan(/\|\s*+(\w*) ([<>=]*) (\d*)/)
      arr2 = line.scan(/: ([A-Z]*) \((\d*.\d*)\/(\d*.\d*)\)/)
      arr2 = line.scan(/: ([A-Z]*) \((\d*.\d*)\)/) if arr2.empty?
      LogicRow.new(*[layer, level, arr, arr2].flatten)
    end

    # @return proc object which can be called to classify at that level
    def self.write_classifier_to_ruby_code(rows, level, filename = nil)
      filename ||= "WEKA_#{level}_classifer.rb"
      to_code = [] 
      # Introductory code goes here
      to_code << "lambda do |molecule_hash|"
      to_code << "assignment = Assignment.new"

      # Here's the parsed stuff
      curr_layer = 0
      rows.map do |row|
        while curr_layer > row.layer
          to_code << "#{"\t"*curr_layer}end"
          curr_layer -= 1
        end
        curr_layer = row.layer
        to_code << "#{"\t"*row.layer}if molecule_hash[:#{row.parameter}].first #{row.logic_operator} #{row.number}"
        if row.assignment
          to_code << "#{"\t"*(row.layer+1)}assignment.#{row.level} = :#{row.assignment}"
          to_code << "#{"\t"*(row.layer)}end"
        end
      end # rows.map
      while curr_layer > 1
        to_code << "#{"\t"*(curr_layer-1)}end"
        curr_layer -= 1
      end
      # close out the introductory code`
      to_code << "\tend #END pregenerated"
      to_code << "\tassignment.to_s"
      to_code << "end #HASH"

      if TOFILE
        # Add debugging code
        if DEBUG
          to_code << <<-EOT
\nif $0 == __FILE__
  $LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))
  require 'lipid_classifier'

  lmid = "LMFA01010001"

  hash = LipidClassifier::Rules.analyze_lmid lmid

  p classify.call hash
end
        EOT
        end
        File.open(filename, 'w') do |fileio|
          fileio.puts to_code
        end
      else # NOT TOFILE
        eval to_code.join("\n"), bind_into_class
      end
    end # self.write_classifier_to_ruby_code
  end # WEKA
end #LipidClassifier



if $0 == __FILE__
  # Test it here
  # PARSE a file
  lines = File.readlines("category_classifier_from_WEKA.txt")


  # Test lines
  testlines = ["not_hydrogen_count > 68", "|   single_ether > 0: PR (6.0)", "phenyl_count > 1", "|   hydrogen_atom_count <= 47", "|   |   valine <= 0", "|   |   |   not_hydrogen_count <= 17", "|   |   |   |   triple_alanine <= 0: PK (25.0/1.0)", "|   |   |   |   triple_alanine > 0: PR (3.0)", "|   |   |   not_hydrogen_count > 17: PK (820.0/2.0)", "|   |   valine > 0", "|   |   |   ketone <= 0: PR (5.0/1.0)", "|   |   |   ketone > 0: PK (9.0)", "|   hydrogen_atom_count > 47", "|   |   hydroxyl_count <= 4: PR (8.0/1.0)", "|   |   hydroxyl_count > 4: PK (3.0)"]

  extracted_lines = testlines.map {|a| LipidClassifier::Utilities::WEKA.line_filter(a.chomp, "category")}

  category_classifier_lambda = LipidClassifier::Utilities::WEKA.write_classifier_to_ruby_code extracted_lines
  p category_classifier_lambda.call Rubabel["LMFA01010001", :lmid]
end
