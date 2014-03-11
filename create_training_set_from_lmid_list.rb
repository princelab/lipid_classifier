require_relative 'lib/lipid_classifier'

lmid_file = ARGV.first 

lmids = File.readlines(lmid_file).uniq

output = lmids.map do |lmid|
  lmid.chomp!
  hash = {}
  hash[:lmid] = lmid
  hash[:href] = "/data/LMSDRecord.php?LMID=#{lmid}"
  hash[:classification] = LipidClassifier.parse_classification_from_LMID lmid
  hash
end

File.open(File.absolute_path(lmid_file).gsub(File.extname(lmid_file), '.yml'),'w') do |io|
  YAML.dump(output, io)
end





