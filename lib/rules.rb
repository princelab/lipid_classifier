$:.unshift(File.dirname(__FILE__))

require 'lipid_classifier'
require 'utilities/booleans'
require 'utilities/progress'
require 'utilities/thread-pool'
require 'fileutils'
require 'timeout'

Dir.glob(File.join(File.dirname(File.absolute_path(__FILE__)),"rules", "*.rb")).map {|rfile| require rfile }



NumberNames = {1 =>  "single", 2 =>  "double", 3 =>  "triple", 4 =>  "quadruple"}
class LipidClassifier
  class Rules    
    #PARAMETERS
    AARuleMax = 2
    SMRuleMax = 3
    # Helpers
    def self.lambda_smart_match_bool(searches, match_count = 1)
      lambda do |molecule| 
        searches.map {|search| molecule.matches(search, uniq: true).size > (match_count - 1)}
      end
    end
    def self.lambda_smart_match_bool_by_count(searches, match_count = 1)
      lambda do |molecule| 
        searches.map {|search| molecule.matches(search, uniq: true).size == match_count}
      end
    end
    def self.lambda_smart_match_count(searches)
      lambda do |molecule| 
        searches.map {|search| molecule.matches(search, uniq: true).size } 
      end
    end
    def self.lambda_smart_match_bool_both(searches, count = 0)
      lambda do |molecule|
        searches.map {|search| molecule.matches(search, uniq: true) > count}.reduce {|r,e| r && e}
      end
    end
    def self.lambda_smart_match_count_both(searches)
      lambda do |molecule| 
        resp = searches.map {|search| molecule.matches(search, uniq: true).size }
        resp.reduce(true) {|r,e| r && e > 0 }
      end
    end
    def self.method_add_to_hash_from_smarts_and_count(hash, smart_key, number, lookup_hash = Smarts)
      new_key = [NumberNames[number], smart_key.to_s].join("_").to_sym
      hash[new_key] = lambda_smart_match_bool_by_count(lookup_hash[smart_key], number)
    end
    def self.method_add_to_hash_from_smarts_and_count_for_amino_acids(hash, smart_key, number, lookup_hash = Smarts)
      new_key = [NumberNames[number], smart_key.to_s].join("_").to_sym
      hash[new_key] = lambda_smart_match_bool_both(lookup_hash[smart_key], number)
    end

    # BOOLEAN responses, or numbers
    #TestBlock = {:test => lambda {|molecule| molecule.each_match("c1ccccc1", uniq: true).to_a.size > 0}, #BENZENE }
    #TestHash = {:ester => ["[#6][CX3](=O)[OX2H0][#6]"]}
    #(1..4).to_a.map {|i| method_add_to_hash_from_smarts_and_count(TestBlock, :ester, i, TestHash) }

    def self.analyze(molecule, lmid = nil)
      # returns a hash, so no association is lost.  
      analysis = {:csmiles => molecule.csmiles, :mass => molecule.mass}
      if analysis[:csmiles].size < 1
        analysis[:csmiles] = "undetermined"
        return nil
      end
      if lmid
        analysis[:lmid] = lmid ? lmid : "PLACE_HOLDER_LMID"
        classification = LipidClassifier.parse_classification_from_LMID(lmid)
        analysis[:category_code] = classification.category_code
        analysis[:class_code] = classification.class_code.to_i
        analysis[:subclass_code] = classification.subclass_code.to_i
        analysis[:class_level4_code] = classification.class_level4_code ? classification.class_level4_code.to_i : '?'
        analysis[:identifier] = classification.identifier.to_i
      else
        analysis[:lmid] = nil
        analysis[:category_code] = nil
        analysis[:class_code] = nil
        analysis[:subclass_code] = nil
        analysis[:class_level4_code] = nil
        analysis[:identifier] = nil
      end
      Smarts.map do |rule|
        errors = []
        begin 
          analysis[rule.first] = rule.last.call(molecule)
        rescue => e
          errors <<  "Rule contains an invalid smarts string:\n\t#{rule.first}\n\t\t#{e}"
        end
        File.open('smart_error.log', 'a') {|i| i.puts errors }
      end
      analysis
    end

    def self.analyze_lmid(lmid)
      begin
        analyze(::Rubabel[lmid, :lmid], lmid)
      rescue ArgumentError => e
        puts e
        puts lmid
        nil
      end
    end
    def self.analyze_set_of_lmids(lmids)
      #returns an array of hashes
      prog = Utilities::Progress.new("Analyzing all classifications")
      total = lmids.size
      count,num = 0,0
      step = total/100.0
      resp = lmids.map do |lmid| 
        if count > step *(num+1)
          num = ((count/total.to_f)*100.0).to_i
          prog.update(num)
        end
        analyze_lmid(lmid)
      end
      prog.finish!
      resp.compact
    end
    def self.analyze_classifications(array) 
      prog = Utilities::Progress.new("Analyzing all classifications")
      total = array.size
      count,num = 0,0
      step = total/100.0
      resp = array.map do |hash| 
        if count > step *(num+1)
          num = ((count/total.to_f)*100.0).to_i
          prog.update(num)
        end
        analyze_lmid(hash[:lmid])
      end
      prog.finish!
      resp.compact
    end
    def self.write_analysis_to_csv_file(array, file = "testing.csv")
      array = [array] unless array.is_a?(Array)
      File.open(file, "w") do |outputter|
        parsing_keys = array.first.keys
        outputter.puts parsing_keys.join(',')
        array.each do |hash|
          next if hash.nil?
          entries = []
          parsing_keys.each do |key|
            v = hash[key]
            if v.class == Array
              entries << v.reduce{|r,e| r || e}
            else
              entries << v
            end
          end
          outputter.puts entries.join(",")
        end
      end
    end
    def self.append_analysis_to_arff_file(array, filename)
      raise ArgumentError unless File.exists?(filename)
      array = [array] unless array.is_a?(Array)
      File.open(filename, "a") do |outputter|
        parsing_keys = array.first.keys
        array.map do |hash|
          next if hash.nil?
          entry = []
          parsing_keys.map do |k|
            if hash[k].class == Array
              entry << hash[k].reduce{|r,e| r || e}
            elsif hash[k].nil?
              entry << "?"
            else
              entry << hash[k]
            end
          end
          outputter.puts entry.join(",")
        end
      end
    end
    def self.write_analysis_to_arff_file(array, file = "testing.arff")
      FileUtils.mkdir_p File.dirname(file)
      array = [array] unless array.is_a?(Array)
      File.open(file, "w") do |outputter|
        outputter.puts %{
% This is output from lipid_classifier
% Anything you see here was generated by code and should be modified therein
@relation LipidClassification-#{DateTime.now.to_s}
        }
        parsing_keys = array.first.keys
        parsing_keys.each do |key| 
          case array.first[key]
          when String
            if LipidClassifier::CategoryCodeToNameMap.keys.include?(array.first[key].to_sym)
              outputter.puts "@attribute #{key.to_s} {#{LipidClassifier::CategoryCodeToNameMap.keys.map(&:to_s).join(",")}}"
            else
              outputter.puts "@attribute #{key.to_s} string"
            end
          when TrueClass, FalseClass
            outputter.puts "@attribute #{key.to_s} numeric"
          when Float, Fixnum, NilClass, Array
            outputter.puts "@attribute #{key.to_s} numeric"
          end #case
        end
        outputter.puts "@DATA"
        array.map do |hash|
          next if hash.nil?
          entry = []
          parsing_keys.map do |k|
            if hash[k].class == Array
              entry << hash[k].reduce{|r,e| r || e}
            elsif hash[k].nil?
              entry << "?"
            else
              entry << hash[k]
            end
          end
          outputter.puts entry.join(",")
        end
      end
    end
    def investigate_layer(root_hash, root_folder, id_symbol_to_sort_by)
      keys = root_hash.keys.uniq
      keys.each {|k| new_folder = FileUtils.mkdir_p(File.join(root_folder, k.to_s)) }
      root_hash.each do |k,v|
        filename = File.join(root_folder, "#{k.to_s}.arff")
        layer = Hash.new {|h,k| h[k] = [] }
        v.map {|a| layer[a[id_symbol_to_sort_by]] << a }
        write_analysis_to_arff_file(v, filename)
      end
      layer
    end
    def self.write_layers_to_distributed_arffs(array, folder = "layers")
      FileUtils.mkdir_p folder
      category_layers = Hash.new {|h,k| h[k] = [] }
      LipidClassifier::CategoryCodeToNameMap.keys.map do |key| 
#        array[1] = nil # What?  Why was I doing this?
        array.map do |entry_hash| 
          begin
            category_layers[key] << entry_hash if entry_hash[:category_code].to_sym == key 
          rescue NoMethodError => e
            if entry_hash.nil?
              p array.first
              puts "EMPTY ENTRY_HASH"
              next
            end
          end
        end
      end
      p category_layers.keys
      write_analysis_to_arff_file(array, File.join(folder, "root.arff")) unless LipidClassifier::Multithreaded
      #  RECURSIVE IS THE PROBLEM... investigate_layer(category_layers, folder, :class_code)
      write_layers_to_arffs(folder, category_layers, 1) # ADD THREAD POOL TO MAKE WRITING LESS IO dependent
    end
    def self.mutex_write_data_to_arff_file(filename, v)
      putsv "Writing: #{filename}"
      Timeout::timeout(3.0) { File.open(filename, 'a').flock(File::LOCK_EX) } rescue binding.pry
      if File.zero? filename
        write_analysis_to_arff_file(v, filename)
      else
        append_analysis_to_arff_file(v, filename)
      end
      File.open(filename, 'a').flock(File::LOCK_UN)
    end

    def self.write_layers_to_arffs(root_folder, hash, code_i)
      codes = [:category_code, :class_code, :subclass_code, :class_level4_code]
      return if code_i > 3
      hash.each do |k,v|
        next if v.size < 1
        subfolder = File.join(root_folder, k.to_s)
        key_code = codes[code_i]
        FileUtils.mkdir_p subfolder
        filename = File.join(root_folder, "#{k.to_s}.arff")
        putsv "Writing: #{filename}"
        mutex_write_data_to_arff_file(filename, v) # Write the file within the other fxn     
        subhash = Hash.new {|h,k| h[k] = [] }
        v.map do |a| 
          subhash[a[key_code]] << a
        end
        write_layers_to_arffs(subfolder, subhash, code_i+1) # Recursive right here!
      end
    end

    def self.create_set_of_rules_from_smart(smart_key, rule_set = Smarts)
      # returns a hash of generated rules
      hsh = {}
      hsh[smart_key] = lambda_smart_match_bool(rule_set[smart_key])
      (1..SMRuleMax).to_a.map {|i| method_add_to_hash_from_smarts_and_count(hsh, smart_key, i, rule_set) }
      hsh[[smart_key.to_s,"count"].join("_").to_sym] = lambda_smart_match_count(rule_set[smart_key])
      hsh
    end
    def self.create_amino_acid_rules_from_smart(smart_key, rule_set = AminoAcids)
      # returns a hash of generated rules
      hsh = {}
      hsh[smart_key] = lambda_smart_match_bool_both(rule_set[smart_key])
      (1..AARuleMax).to_a.map {|i| method_add_to_hash_from_smarts_and_count_for_amino_acids(hsh, smart_key, i, rule_set) }
      hsh[[smart_key.to_s,"count"].join("_").to_sym] = lambda_smart_match_count_both(rule_set[smart_key])
      hsh
    end

    # ON LOADING 
    # Install the base rules
    FunctionalGroups.each do |k,v|
      Smarts.merge! create_set_of_rules_from_smart(k, FunctionalGroups)
    end
    AminoAcids.each do |k,v|
      Smarts.merge! create_amino_acid_rules_from_smart(k, AminoAcids)
    end
  end
end

#LipidClassifier::Rules.prep_rules
# Generate rules for all the SMARTS


if $0 == __FILE__
  mol = Rubabel["LMFA01010001", :lmid]
  classifier = LipidClassifier::Rules
  #analysis = classifier.analyze mol, "LMFA01010001"
  #analysis = classifier.analyze_set_of_lmids(["LMFA01010001", "LMFA01010002","LMGP01010001"])
  
  #classifier.write_analysis_to_csv_file(analysis, "testing.csv")
  #classifier.write_analysis_to_arff_file(analysis, "testing.arff")
  #classifier.write_layers_to_distributed_arffs(analysis)

  #puts "Should be true: #{LipidClassifier::Rules::TestBlock[:test].call Rubabel["C1=CC=CC=C1"]}"
  #puts "ARE YOU SURE? You'll have to comment out the code to run these..."
  #File.open("amino_acids.yml", "w") {|f| f.write YAML.dump LipidClassifier::Rules::AminoAcids}
  #File.open("smart_search_strings.yml", "w") {|f| f.write YAML.dump LipidClassifier::Rules::SmartSearchStrings}
end
