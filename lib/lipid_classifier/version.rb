class LipidClassifier
  versionterms = File.readlines("../../VERSION").first.split(/(\.|-)/)

  VERSION = versionterms.join(".")
end
