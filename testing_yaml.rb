require 'yaml'

hsh = YAML.load_file("test.yml")

puts hsh[:Z_config_nonspecif_1]
