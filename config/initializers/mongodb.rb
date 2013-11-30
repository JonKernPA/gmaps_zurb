# Set up database name, appending the environment name (e.g., tml-development, tml-production)
MongoMapper.config = {
    Rails.env => { 'uri' => ENV['MONGOHQ_URL'] ||
        'mongodb://localhost/sushi' } }
MongoMapper.connect(Rails.env)
name = "gmaps-zurb-#{Rails.env}"
if ENV['MONGOHQ_URL']
  uri = URI.parse(ENV['MONGOHQ_URL'])
  name = uri.path.gsub(/^\//, '')
  puts "Env = #{ENV['MONGOHQ_URL']}; DB NAME: #{name}"
end
MongoMapper.database = "#{name}"
