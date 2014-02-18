require 'spec_helper'
require 'yaml'
puts File.join(File.dirname(__FILE__), "..", "smarts_check_smiles.yml" )
SMARTS = YAML.load_file(File.join(File.dirname(__FILE__), "..", "smarts_check_smiles.yml" ))

describe "Testing our SMARTS substructure searches" do 
  describe "Simple tests" do 
    SMARTS[:simple_tests].each do |k,arr|
      it "#{k} works" do 
        mol = Rubabel[arr.first]
        analysis = LipidClassifier::Rules.analyze mol
        thing_that_should_be_true = k.to_s.sub("_check",'')
        if analysis[thing_that_should_be_true.to_sym] == [false]
          p thing_that_should_be_true
          p mol
          binding.pry
        end
        analysis[thing_that_should_be_true.to_sym].include?(true).should be_true
        analysis["single_#{thing_that_should_be_true}".to_sym].include?(true).should be_true
        analysis["#{thing_that_should_be_true}_count".to_sym].any? {|a| a > 0}.should be_true
      end
    end
  end
end

