class LipidClassifier
  versionterms = File.readlines(File.join(File.dirname(__FILE__), "../../VERSION")).first.chomp.split(/(\.|-)/).delete_if{|a| a[/(\.|-)/] }

  VERSION = versionterms.join(".")
end
