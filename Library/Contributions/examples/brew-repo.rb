require 'repository'

puts "Repo:", DEFAULT_REPOSITORY
puts "Path:", DEFAULT_REPOSITORY.path
puts "Names..."
puts DEFAULT_REPOSITORY.names[0..5]
puts "Aka..."
puts DEFAULT_REPOSITORY.aliases[0..5]
