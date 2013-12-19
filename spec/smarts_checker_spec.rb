require 'spec_helper'

describe "Testing our SMARTS substructure searches" do 
  require 'yaml'
  puts File.join(File.dirname(__FILE__), "..", "smarts_check_smiles.yml" )
  YAML.load_file(File.join(File.dirname(__FILE__), "..", "smarts_check_smiles.yml" ))
end

