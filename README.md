## Google Maps for Rails 4 and MongoDB Example App

## Related GMaps4Rails Projects
* [gmaps](https://github.com/JonKernPA/gmaps): Standard Rails4, ActiveRecord, standard UI
* [gmaps_mongo](https://github.com/JonKernPA/gmaps_mongo): Rails4, MongoDB, standard UI
* [gmaps_zurb](https://github.com/JonKernPA/gmaps_zurb): Rails4, MongoDB, Zurb Foundation

## Tech Stack

This application requires:

* Ruby version 2.0.0
* Rails version 4.0.1
* [MongoDB](http://www.mongodb.org/)
* [MongoMapper](https://github.com/mongomapper/mongomapper)
* [Zurb Foundation 5.0](http://foundation.zurb.com/)
* [gmaps4rails](https://github.com/apneadiving/Google-Maps-for-Rails)

## Companion Video

From the [gmaps4rails](https://github.com/apneadiving/Google-Maps-for-Rails) github site,
which references a [quick tutorial on Youtube](http://www.youtube.com/watch?v=R0l-7en3dUw&feature=youtu.be).

I created these steps so that I could be sure on the proper steps to get gmaps working.

## Demo Steps

### Create New Rails App

Bootstrap the rails app inside an RVM setup ([RVM](http://rvm.io/) is optional)

```
$ mkdir gmaps_zurb
$ cd gmaps_zurb/
$ rvm use ruby-2.0.0@gmaps_zurb --ruby-version --create
Using /Users/jon/.rvm/gems/ruby-2.0.0-p247 with gemset gmaps_zurb
$ gem install rails
```

use the `-T` flag to skip Test::Unit files or the `-O` flag to skip Active Record files:

```
rails new . -m https://raw.github.com/RailsApps/rails-composer/master/composer.rb -T -O

Install an example application for Rails 4.0?
	3)  I want to build my own application

Web server for development?
	2) Thin

Web server for production?
	1)  Same as development

Database used in development?
	4) MongoDB

How will you connect to MongoDB?
	1) Mongoid <-- Choose this even though we will use MongoMapper

Template engine?
	1) Haml

Unit testing?
	2)  RSpec

Integration testing?
	3)  Cucumber with Capybara

Continuous testing?
	1)  None

Fixture replacement?
	2)  Factory Girl  <-- Though I also like Fabrication

Front-end framework?
	2)  Zurb Foundation 5.0

Add support for sending email?
	1)  None

Authentication?
	1)  None

Authorization?
	1)  None

Use a form builder gem?
	1)  None

Install a starter app?
	1)  None

Set a robots.txt file to ban spiders? (y/n) y
Create a GitHub repository? (y/n) y
Use application.yml file for environment variables? (y/n) y
Reduce assets logger noise during development? (y/n) y
Improve error reporting with 'better_errors' during development? (y/n) y

Okay to drop all existing databases named gmaps_zurb? 'No' will abort immediately! (y/n) y
```

Gemfile, add `mongo_mapper`

```ruby
gem 'mongo_mapper', :git => "git://github.com/mongomapper/mongomapper.git", :tag => "v0.13.0.beta2"
```

And delete the `mongoid` and `mongoid-rspec` gems

```ruby
gem 'mongoid', '~> 4', :github=>"mongoid/mongoid"
gem 'mongoid-rspec', '>= 1.6.0', :github=>"evansagge/mongoid-rspec"
```

In application.rb, add `g.orm :mongo_mapper`

```ruby
config.generators do |g|
  g.orm :mongo_mapper
  g.test_framework :rspec, fixture: true
  g.fixture_replacement :factory_girl, dir: 'spec/factories'
  g.view_specs false
  g.helper_specs false
end
```

Delete `config/mongoid.yml`

Add `config/mongodb.yml`

```ruby
defaults: &defaults
  host: 127.0.0.1
  port: 27017

development:
  <<: *defaults
  database: gmaps_zurb-development
  host: localhost
  logger: mongo

test: &test
  <<: *defaults
  database: gmaps_zurb-test
  host: localhost

cucumber:
  <<: *test

qa:
  <<: *defaults
  database: gmaps_zurb-qa
  host: localhost

production:
  <<: *defaults
  database: gmaps_zurb-development
  host: localhost
```

Add to `config/initializers`

Create `mongodb.rb`

```ruby
# Set up database name, appending the environment name (e.g., tml-development, tml-production)
MongoMapper.config = {
    Rails.env => { 'uri' => ENV['MONGOHQ_URL'] ||
        'mongodb://localhost/sushi' } }
MongoMapper.connect(Rails.env)
name = "gmaps-zurb-#{Rails.env}"
if ENV['MONGOHQ_URL']
  uri = URI.parse(ENV['MONGOHQ_URL'])
  name = uri.path.gsub(/^\//, '')
  # Env = mongodb://heroku:3n2v8bhhita6cifm31x0ta@flame.mongohq.com:27103/app556153; DB NAME: app556153
  # mongodb://<user>:<password>@staff.mongohq.com:10032/app2268477
  puts "Env = #{ENV['MONGOHQ_URL']}; DB NAME: #{name}"
end
MongoMapper.database = "#{name}"
```

Create `mongomapper.rb`

```ruby
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
```

Do the usual

```
bundle install
```

### Create User Model

The user will have lat/lon data

```
rails g scaffold User latitude:float longitude:float address:string description:string title:string
```

### Add Address Geocoding

In Gemfile, add:

```ruby
gem 'geocoder'
```

In `routes.rb` add `root 'users#index'`

```ruby
Gmaps::Application.routes.draw do
  resources :users
  root 'users#index'
end
```

Modify `model/user.rb` -- with MongoMapper and MongoDB, we need to do more than if we were using ActiveRecord...

* Add the Geocoder bits
* Create a 2D array for the coordinates
* Marshal the geocoded lat/lon into the 2D array elements (as lon/lat!!)

And, this necessitated adding some smarts to only geocode when there is an address and no lat/lon.
And to only reverse geocode (lookup an address) if there is a lat/lon and no address.

```ruby
class User
  include MongoMapper::Document
  include Geocoder::Model::MongoMapper

  key :latitude, Float
  key :longitude, Float
  key :address, String
  key :description, String
  key :title, String

  key :coordinates, :type => Array
  ensure_index [[:coordinates, "2d"]]

  geocoded_by :address
  # reverse geocode a street address using a user-entered lat/lon.
  reverse_geocoded_by :coordinates

  after_validation :look_up_address, :if => :has_lat_lon, :unless => :has_address
  after_validation :geocode, :if => :has_address, :unless => :has_lat_lon

  before_save :store_geo, :unless => :has_lat_lon

  private

  def look_up_address
    self.coordinates = [self.longitude, self.latitude]
    reverse_geocode
  end

  def has_address
    !self.address.blank?
  end

  def has_lat_lon
    self.latitude && self.longitude
  end

  # Marshal the geocoded lat/lon into the 2D array elements (as lon/lat!!)
  def store_geo
    self.longitude = self.coordinates[0]
    self.latitude = self.coordinates[1]
  end

end
```

Start Rails

```
bundle install
rails s
```

### Create a New User

In the App, create a new user, add an address (for example, "New York, NY" -- do not enter a lat or lon), save new user.

*Assert:* You should see lat/lon geocoded...

### Add Gmaps4Rails

In Gemfile

```ruby
gem 'gmaps4rails'
```

```
bundle install
rails s
```

### Add Map Div

#### Haml

Inside `users/index.html.haml`, add the following at the bottom of page:

```erb
%div{style: "width: 800px;"}
  #map{style: "width: 800px; height: 400px;"}%h1 Listing users
```

#### ERB

Inside `users/index.html.erb`, add the following at the bottom of page:

```erb
<div style='width: 800px;'>
  <div id="map" style='width: 800px; height: 400px;'></div>
</div>
```

### Add Map Javascript

It is critical when using Foundation (and anything, really) to call GMaps only after the script containing it is loaded.

#### Haml

Benjamin Roth mentioned:

> Explanation is you put `= javascript_include_tag "application"` at the bottom of your html
> to meet Foundation's expectations. So every previous javascript will fail.
 > Solution: you have to put your scripts after the files defining them.
>
> So AFTER `= javascript_include_tag "application"`, add:
>
> `= yield :scripts`
>
> And then whenever you need in a view:
>
> ```haml
> - content_for :scripts do
>   :javascript
>     // Gmaps can be called safely here...
> ```

### Layout

In the `views\layout\application.html.haml`

#### Haml

```javascript
= javascript_include_tag "application"
= yield :scripts
```

#### Haml

Put the following at the top of the `users/index.html.haml` page

```javascript
%script{src: "//maps.google.com/maps/api/js?v=3.13&sensor=false&libraries=geometry", type: "text/javascript"}
%script{src: "//google-maps-utility-library-v3.googlecode.com/svn/tags/markerclustererplus/2.0.14/src/markerclusterer_packed.js", type: "text/javascript"}
```
#### ERB

Put the following at the top of the `users/index.html.erb` page

```javascript
<script src="//maps.google.com/maps/api/js?v=3.13&sensor=false&libraries=geometry" type="text/javascript"></script>
<script src="//google-maps-utility-library-v3.googlecode.com/svn/tags/markerclustererplus/2.0.14/src/markerclusterer_packed.js" type="text/javascript"></script>
```

### Underscores.js

Visit [http://underscorejs.org/underscore-min.js](http://underscorejs.org/underscore-min.js).
Select Production Version, copy all text or do right-click, Save As...

Add this file under `vendor` as follows:

```
vendor/assets/javascripts/underscore.js
```

### Asset Pipeline

Add underscore and gmaps to `app/assets/javascripts/application.js`

```ruby
//= require jquery
//= require jquery_ujs
//= require turbolinks
//= require underscore
//= require gmaps/google
//= require_tree .
```

(leaving `require_tree .` as last line)

### Map Generation Script

Add the map script to the bottom of the view, below the div.

Note: this has dummy marker data at a lat/lon of 0,0 :-)

#### Haml

```javascript
- content_for :scripts do
  :javascript
    handler = Gmaps.build('Google');
    handler.buildMap({ provider: {}, internal: {id: 'map'}}, function(){
      markers = handler.addMarkers([
        {
          "lat": 0,
          "lng": 0,
          "picture": {
            "url": "https://addons.cdn.mozilla.net/img/uploads/addon_icons/13/13028-64.png",
            "width":  36,
            "height": 36
          },
          "infowindow": "hello!"
        }
      ]);
      handler.bounds.extendWith(markers);
      handler.fitMapToBounds();
    });
```

#### ERB

```javascript
content_for :scripts do
  <script type="text/javascript">
    handler = Gmaps.build('Google');
    handler.buildMap({ provider: {}, internal: {id: 'map'}}, function(){
      markers = handler.addMarkers([
        {
          "lat": 0,
          "lng": 0,
          "picture": {
            "url": "https://addons.cdn.mozilla.net/img/uploads/addon_icons/13/13028-64.png",
            "width":  36,
            "height": 36
          },
          "infowindow": "hello!"
        }
      ]);
      handler.bounds.extendWith(markers);
      handler.fitMapToBounds();
    });
  </script>
```

### Assert: Map Should be Visible

Refresh the view... Now you should see a map!

If you don't see a map, something is wrong.

### Generate Map Datapoints

Add to the controller the generation of the mapping datapoints from the user records:

```ruby
  def index
    @users = User.all
    @hash = Gmaps4rails.build_markers(@users) do |user, marker|
      next if user.latitude.nil? || user.longitude.nil?
      marker.lat user.latitude
      marker.lng user.longitude
      marker.title user.title
    end
  end
```

Replace the dummy marker data in the view script with data from the model:

#### Haml
```javascript
markers = handler.addMarkers(#{raw @hash.to_json});
```

#### ERB

```javascript
markers = handler.addMarkers(<%=raw @hash.to_json %>);
```

### Assert: Map Should be Visible

Be sure to add a couple of User records with addresses (and verify the geocoding worked).

Refresh the users page.

Now you should see a map with your user datapoints...

If you do not see the individual user datapoints, then something is wrong.

## Rails Composer

This application was generated with the [rails_apps_composer](https://github.com/RailsApps/rails_apps_composer) gem provided by the [RailsApps Project](http://railsapps.github.io/).

## Diagnostics

This application was built with recipes that are known to work together.

Recipes:
["apps4", "controllers", "core", "email", "extras", "frontend", "gems", "git", "init", "models", "prelaunch", "railsapps", "readme", "routes", "saas", "setup", "testing", "views"]

Preferences:
{:git=>true, :apps4=>"none", :dev_webserver=>"thin", :prod_webserver=>"thin", :database=>"mongodb", :orm=>"mongoid", :templates=>"haml", :unit_test=>"rspec", :integration=>"cucumber", :continuous_testing=>"none", :fixtures=>"factory_girl", :frontend=>"foundation5", :email=>"none", :authentication=>"none", :authorization=>"none", :form_builder=>"none", :starter_app=>"none", :quiet_assets=>true, :local_env_file=>true, :better_errors=>true, :ban_spiders=>true, :github=>true}

## Ruby on Rails

Learn more about [Installing Rails](http://railsapps.github.io/installing-rails.html).

## Database

This application uses MongoDB with the MongoMapper ORM (above, we change out mongoid for mongo_mapper).

## Development

* Template Engine: ERB
* Testing Framework: RSpec and Factory Girl and Cucumber
* Front-end Framework: None
* Form Builder: None
* Authentication: None
* Authorization: None

## Contributing

If you make improvements to this application, please share with others.

* Fork the project on GitHub.
* Make your feature addition or bug fix.
* Commit with Git.
* Send the author a pull request.

If you add functionality to this application, create an alternative implementation, or build an application that is similar, please contact me and I'll add a note to the README so that others can find your work.

## Credits

All the great gem, rvm, and rails authors

## License

MIT License
