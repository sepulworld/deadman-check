require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList['test/**/*_test.rb']
end

task :default => :test

desc "Docker build image"
task :docker_build do
  sh %{docker build -t sepulworld/deadman-check .}
end

desc "Push Docker image to Docker Hub"
task :docker_push do
  sh %{docker push sepulworld/deadman-check}
end

desc "Pull Docker image to Docker Hub"
task :docker_pull do
  sh %{docker pull sepulworld/deadman-check}
end
