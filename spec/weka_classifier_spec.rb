require 'spec_helper'

describe LipidClassifier::WEKA do 
  describe "#classify_lipid_by_lmid"
  describe "#determine_current_level_by_filestructure" do 
    it "should provide the classification level for a given ARFF file" do 
      tests = [["full_layers/FA/1/1.arff", "subclass"],
        ["~/Dropbox/coding/lipid_classifier/full_layers/ST/5/5.arff", "subclass"], 
        ["full_layers/FA/1.arff", "class"], 
        ["full_layers/FA/1/1/1.arff", "class_level4"]]
      tests.map do |path, level|
        resp = LipidClassifier::WEKA.determine_current_level_by_filestructure(path)
        #puts "PATH: #{path} \t RESP: #{resp}"
        resp.should == level
      end
      error_test = "1/1.arff"
      expect {LipidClassifier::WEKA.determine_current_level_by_filestructure(error_test)}.to raise_error(ArgumentError)
    end
  end  
  describe "#parse_ontology_from_filestructure" do 
    it "should provide the classification of a given ARFF file" do 
      tests = ["full_layers/FA/1/1.arff",
        "~/Dropbox/coding/lipid_classifier/full_layers/ST/5/5.arff",
        "full_layers/FA/1.arff",
        "full_layers/FA/1/1/1.arff"]
      tests.map do |path|
        resp = LipidClassifier::WEKA.parse_ontology_from_filestructure(path)
        #puts "PATH: #{path} \t RESP: #{resp}"
        p resp
      end
      error_test = "1/1.arff"
      expect {LipidClassifier::WEKA.parse_ontology_from_filestructure(error_test)}.to raise_error(ArgumentError)
    end
  end
  describe "#load_classifications" do 
    it "should load up ~359 classifiers from code" do 
      resp = LipidClassifier::WEKA.load_classifications("full_layers")
    end
  end
  describe "#line_filter" do 
    it "should handle normal cases" do 
      truth = LipidClassifier::WEKA::LogicRow.new(0, "category", "valine_count", ">", "0", "FA", '100')
      teststring = "valine_count > 0: FA (100)"
      ans = LipidClassifier::WEKA.line_filter(teststring, "category")

      ans.should == truth
    end
  end
end


