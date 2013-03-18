# load all the necessary files for the app to run

require File.expand_path('./app/routes/base')

# load models
Dir.open("./app/models").each do |file|
  next if file =~ /^\./
  require File.expand_path("./app/models/#{file}")
end

# load routes
%w[api web].each do |app|
  require File.expand_path("./app/routes/#{app}")
  Dir.glob("./app/routes/#{app}/*.rb").each do |relative_path|
    require relative_path
  end
end
