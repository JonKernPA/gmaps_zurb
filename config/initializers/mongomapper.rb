require 'mongo_mapper'
# MongoMapper logging: control by 'logname' option in mongo.yml
# if logname option omitted or set to 'none', disable logging.
# if logname set to 'rails' or 'default', use MongoMapper default log.
# otherwise, log to file log/<logname>_<environment>.log
logname = MongoMapper.config[Rails.env]['logger']
if logname.nil? || logname == 'none'
  MongoMapper.connection.instance_variable_set(:@logger, nil)
elsif logname != 'rails' && logname != 'default'
  logger           = Logger.new(File.join(Rails.root, "/log/#{logname}_#{Rails.env}.log"), 'daily')
  logger.formatter = Logger::Formatter.new
  logger.datetime_format = "%H:%M:%S %Y-%m-%d"
  MongoMapper.connection.instance_variable_set(:@logger, logger)
end

# setup MongoMapper connection unless Rails app has already done so
unless MongoMapper::Connection.class_variables.include?(:@@database_name)
  env         = ENV['RAILS_ENV'] || 'development'
  config_file = "#{File.dirname(__FILE__)}/../mongodb.yml"
  MongoMapper.config = YAML.load(ERB.new(File.read(config_file)).result)
  MongoMapper.setup MongoMapper.config, env, :pool_size => 30, :pool_timeout => 5
end

puts "Initialized: #{MongoMapper.database.name}"

