require 'rake/testtask'
require "bundler/gem_tasks"

task :default => [:test]

Rake::TestTask.new(:test) do |t|
  t.libs << '.'
  t.pattern = 'test/all.rb'
  t.verbose = true
end
Rake::Task['test'].comment = "Run all tests"
