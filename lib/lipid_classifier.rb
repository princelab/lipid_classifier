require 'rubabel'
require 'pry'

Dir.glob(File.dirname(__FILE__) + "*.rb").map {|f| require f }

class LipidClassifier
  # Load the SMARTS
  require 'yaml'
  SMARTS = YAML.load_file("smart_search_strings.yml")

end
