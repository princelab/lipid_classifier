ARGV.each do |file|
  File.readlines(file).map.with_index {|a,i| puts "vim +#{i} #{file}\n Line looks like: #{a}" if a[/^,/]}
end
