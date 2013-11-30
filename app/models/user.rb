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
