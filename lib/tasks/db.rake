namespace :db do
  desc "Checks if database exists"
    task exists: :environment do
    begin
      ActiveRecord::Base.connection
      exit 0
    rescue
      exit 1
    end
  end
end
