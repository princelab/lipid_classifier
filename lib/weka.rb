require_relative "lipid_classifier"
require_relative "lipidmaps"
require 'open3'
require 'pry'

class LipidClassifier
  class WEKA
    def self.bind_into_class 
      binding
    end
    TOFILE = false
    WEKADEBUG = false
    LogicRow = Struct.new(:layer, :level, :parameter, :logic_operator, :number, :assignment, :correct_count, :wrong_count)
    Assignment = Struct.new(:category, :class, :subclass, :class_level4) do 
      def to_s
        "LM#{@category.to_s}#{@class}#{@subclass}#{@class_level4}"
      end
    end
    ClassifierStruct = Struct.new(:current_layer, :layer_classification, :file, :parents, :classification_lambda)
    @classifiers = Hash.new {|h,k| h[k] = {} }
    Categories = %w{FA GL ST PR SL PK SP GP}
    def self.determine_current_level_by_filestructure(files_match)
      # Requires a valid path
      raise ArgumentError unless File.exists?(File.expand_path(files_match))
      resp = File.basename(files_match) == "root.arff" ? "root" : nil
      file_levels = files_match.split(File::SEPARATOR).delete_if{|a| File.extname(a) == ".arff"}
      #path = File.absolute_path(files_match).split(File::SEPARATOR)[1..-2]
      #while not Categories.include?(file_levels[upper_directories.size])
       # file_levels.unshift path.pop 
        #break if file_levels.size > 4
      #end
      file_levels = file_levels.drop_while {|a| not Categories.include?(a)}
      if resp.nil?
        resp = case file_levels.size
        when 0
          "category"
        when 1
          "class"
        when 2
          "subclass"
        when 3
          "class_level4"
        end
      end
      resp 
    end
    def self.parse_ontology_from_filestructure(files_match)
      raise ArgumentError unless File.exists?(File.expand_path(files_match))
      if File.basename(files_match) == "root_classifier.txt"
        current_level = "root"
        current_layer = 'root'
        file_levels = []
      else
        file_levels = files_match.split(File::SEPARATOR)
        #path = File.absolute_path(files_match).split(File::SEPARATOR)[1..-2]
        #while not Categories.include?(file_levels[upper_directories.size])
        # file_levels.unshift path.pop 
        #break if file_levels.size > 4
        #end
        file_levels = file_levels.drop_while {|a| not Categories.include?(a)}
        current_level = case file_levels.size
        when 0
          "category"
        when 1
          "class"
        when 2
          "subclass"
        when 3
          "class_level4"
        end
        current_layer = File.basename(files_match).gsub("_classifier"+File.extname(files_match),"")
      end
      parents = file_levels[0..-2]
      str = ClassifierStruct.new(current_level, current_layer, files_match, parents)
      str
    end

    def self.run_weka_on_arff_file(file, class_level)
      # 3 different WEKA steps
      remove_string = case class_level
      when "root"
        "1,2,3,5,6,7,8"
      when "category"
        "1,2,3,4,6,7,8"
      when "class"
        "1,2,3,4,5,7,8"
      when "subclass"
        "1,2,3,4,5,6,8"
      when "class_level4"
        "1,2,3,4,5,6,8"
      end

      input_file = file
      tmp_file1 = 'tmp_arff.arff'
      tmp_file2 = 'tmp_arff2.arff'
      output_file = file.gsub(".arff","_for_analysis.arff")
      model_file = file.gsub(".arff", "_classifier.txt")

      #1 Remove
      #2 Nominalize
      #3 Reorder
      #4 Classify with J48
      system "java weka.filters.unsupervised.attribute.Remove -R #{remove_string} -i #{input_file} -o #{tmp_file1}"
      system "java weka.filters.unsupervised.attribute.NumericToNominal -R first -i #{tmp_file1} -o #{tmp_file2}"
      system "java weka.filters.unsupervised.attribute.Reorder -R 2-last,1 -i  #{tmp_file2} -o #{output_file}"
      resp,error,status = Open3.capture3("java weka.classifiers.trees.J48 -C 0.25 -M 2 -t #{output_file} > #{model_file}")
      if error.size > 0
        # right now I handle this downstream
      end
      model_file
    end

    def self.grab_arffs(directory)
      files = Dir.glob(File.join(directory, "*.arff"))
      files <<  Dir.glob(File.join(directory, "*","*.arff"))
      files <<  Dir.glob(File.join(directory, "*","**","*.arff"))
      files.flatten.each do |file|
        class_level = determine_current_level_by_filestructure(file)
        run_weka_on_arff_file(file, class_level)
      end
    end
  
    def self.load_classifications(directory)
      files = Dir.glob(File.join(directory, "*_classifier.txt"))
      files <<  Dir.glob(File.join(directory, "*","*_classifier.txt"))
      files <<  Dir.glob(File.join(directory, "*","**","*_classifier.txt"))
      files.flatten.map do |file|
        lines = parse_classifier_from_raw_weka_output(file)
        struct = parse_ontology_from_filestructure(file)
        name = "#{struct.current_layer}_#{struct.parents.join("-")}-#{struct.layer_classification}"
        conversion_hash = {root: "category", category: "class", class: "subclass", subclass: "class_level4"}
        struct.classification_lambda = write_classifier_to_ruby_code(read_lines(lines, struct.current_layer),conversion_hash[struct.current_layer.to_sym], "#{name}.rb")
        puts "CURR_LAYER: #{ struct.current_layer}"
        case struct.current_layer 
        when "root"
          @classifiers[:root] = struct
        when "category"
          @classifiers[:category][struct.layer_classification.to_sym] = struct
        when "class"
          @classifiers[:class][(struct.parents.join("-")+ "-" + struct.layer_classification).to_sym] = struct
        when "subclass"
          @classifiers[:subclass][(struct.parents.join("-")+ "-" + struct.layer_classification).to_sym] = struct
        when "level4_class"
          @classifiers[:class_level4][(struct.parents.join("-")+ "-" + struct.layer_classification).to_sym] = struct
        end
      end
      @classifiers
    end
    
    def self.parse_classifier_from_raw_weka_output(file)
      if File.zero?(file)
        lines = [File.basename(file).sub(File.extname(file), "")]
      end
      lines = File.readlines(file)
      send_on_lines = []
      parse = false
      lines.each do |line|
        parse = false if line == "\n"
        if parse
          send_on_lines << line
        end
        parse = true if line == "------------------\n"
      end
      send_on_lines
    end

    def self.classify_unknown_lipid(molecule)
      raise ArgumentError unless @classifiers
      analysis = LipidClassifier::Rules.analyze(molecule)
      classification = LipidClassifier::Classification.new
      binding.pry
      classification.category_code = @classifiers[:root].classification_lambda.call analysis
      classification.class_code = @classifiers[:class][classification.category_code.to_sym].classification_lambda.call analysis
      classification.subclass_code = @classifiers[:subclass][[classification.category_code, classification.class_code].join("-").to_sym].classification_lambda.call analysis
      classification.class_level4_code = @classifiers[:class_level4][[classification.category_code, classification.class_code,classification.subclass_code].join("-").to_sym].classification_lambda.call analysis
      classification
    end

    def self.classify_lipid_vs_lmid(lmid)
      raise ArgumentError unless @classifiers
      hash = LipidClassifier::Rules.analyze_lmid(lmid)
      lm_classification = LipidClassifier::LipidMaps.parse_classification_from_lmid(lmid)
      weka_classification = classify_unknown_lipid(Rubabel[lmid,:lmid])
      [lm_classification, weka_classification]
    end

    def self.read_file_for_lines(file)
      # level can be category, class, subclass, level4_class
      level = determine_current_level_by_filestructure(file)
      File.readlines(file).map {|line| line_filter(line, level)}
    end
    def self.read_lines(lines, level)
      lines.map {|line| line_filter(line, level)}
    end

    # level can be root, category, class, subclass, level4_class
    def self.line_filter(line, level)
      layer = line.count "|"
      arr = line.scan(/\s*+(\w*) ([<>=]*) (\d*)/)
      if arr.empty?
        arr = [nil, nil, nil]
      end
      arr2 = line.scan(/: ([A-Z]*) \((\d*.\d*)\/(\d*.\d*)\)/)
      arr2 = line.scan(/: ([A-Z]*) \((\d*.\d*)\)/) if arr2.empty?
      LogicRow.new(*[layer, level, arr, arr2].flatten)
    end

    # @return proc object which can be called to classify at that level
    def self.write_classifier_to_ruby_code(rows, level, filename = nil)
      filename ||= "WEKA_#{level}_classifier.rb"
      to_code = [] 
      # Introductory code goes here
      to_code << "lambda do |molecule_hash|"
      to_code << "  assignment = Assignment.new"

      # Here's the parsed stuff
      curr_layer = 1
      rows.map do |row|
        while curr_layer -1 > row.layer
          to_code << "#{"  "*curr_layer}end"
          curr_layer -= 1
        end
        if row.parameter 
          curr_layer += 1
          to_code << "#{"  "*row.layer}if molecule_hash[:#{row.parameter}].first #{row.logic_operator} #{row.number}"
        end
        if row.assignment
          to_code << "#{"  "*(row.layer+1)}assignment.#{level} = :#{row.assignment}"
        end
      end # rows.map
      while curr_layer > 0
        to_code << "#{"  "*(curr_layer)}end"
        curr_layer -= 1
      end
      # close out the introductory code`
      to_code.insert(-2,"  assignment.to_s")

      if TOFILE
        # Add debugging code
        if WEKADEBUG
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
        filename
      else # NOT TOFILE
        begin 
          eval to_code.join("\n")#, bind_into_class
        rescue SyntaxError, NameError
          File.open("temporary","w") {|i| i.puts to_code.join("\n") }
          puts "ERROR!!!!"
          abort
        end
      end
    end # self.write_classifier_to_ruby_code
  end # WEKA
end #LipidClassifier



if $0 == __FILE__
  # Test it here
  # PARSE a file
  lines = File.readlines("category_classifier_from_WEKA.txt")

  #LipidClassifier::WEKA.grab_arffs("tmp_layers")
  LipidClassifier::WEKA.load_classifications("tmp_layers")
  p LipidClassifier::WEKA.classify_lipid_vs_lmid("LMFA01010001")
  p LipidClassifier::WEKA.classify_unknown_lipid(Rubabel["LMFA01010001",:lmid])
  abort


  # Test lines
  testlines = ["not_hydrogen_count > 68", "|   single_ether > 0: PR (6.0)", "phenyl_count > 1", "|   hydrogen_atom_count <= 47", "|   |   valine <= 0", "|   |   |   not_hydrogen_count <= 17", "|   |   |   |   triple_alanine <= 0: PK (25.0/1.0)", "|   |   |   |   triple_alanine > 0: PR (3.0)", "|   |   |   not_hydrogen_count > 17: PK (820.0/2.0)", "|   |   valine > 0", "|   |   |   ketone <= 0: PR (5.0/1.0)", "|   |   |   ketone > 0: PK (9.0)", "|   hydrogen_atom_count > 47", "|   |   hydroxyl_count <= 4: PR (8.0/1.0)", "|   |   hydroxyl_count > 4: PK (3.0)"]

  extracted_lines = testlines.map {|a| LipidClassifier::WEKA.line_filter(a.chomp, "category")}

  category_classifier_lambda = LipidClassifier::WEKA.write_classifier_to_ruby_code extracted_lines, 'category'
  p ::Rubabel["LMFA01010001", :lmid]
  p category_classifier_lambda.call LipidClassifier::Rules.analyze_lmid("LMFA01010001")
end
