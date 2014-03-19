namespace :hollerback do

  task :reactivate_users do
    Reactivator.perform_async(true)
  end
end