# lib/tasks/cache.rake
namespace :cache do
  desc "Toggle development caching on/off"
  task :toggle do
    cache_file = "#{Rails.root}/tmp/caching-dev.txt"

    if File.exist?(cache_file)
      File.delete(cache_file)
      puts "Development caching is now OFF"
    else
      FileUtils.touch(cache_file)
      puts "Development caching is now ON"
    end
  end
end
