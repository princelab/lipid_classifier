class Hash
  def find_keys(search)
    keys.select {|key| search =~ Regexp.new(key) }
  end
end
