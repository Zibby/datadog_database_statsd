# frozen_string_literal: true

task default: %w[test]

task :install do
  sh "bundle install"
end

task :test do
  sh "bundle install"
  sh "rubocop"
end

task :start do
  sh "bundle exec main.rb"
end
