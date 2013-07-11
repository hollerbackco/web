require File.expand_path('../boot', __FILE__)

# setup local ENV
env_file = File.join('config', 'local_env.yml')

if File.exists?(env_file)
  YAML.load(File.open(env_file)).each do |key, value|
    ENV[key.to_s] ||= value
  end
end

require File.expand_path('../application', __FILE__)
