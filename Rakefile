namespace :app do
  desc 'Run with Rackup'
  task :run do
    Bundler.with_clean_env do
      sh 'bundle exec rackup'
    end
  end

  desc 'Run with Rerun'
  task :rerun do
    Bundler.with_clean_env do
      sh 'bundle exec rerun -b rackup'
    end
  end
end
