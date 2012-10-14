class Location < ActiveRecord::Base
  has_many :user_locations
  has_many :users, :through => :user_locations
  has_many :group_locations
  has_many :groups, :through => :group_locations
  has_many :counties
  
  def self.find_by_geoip(ipaddress = Settings.request_ip_address)
    if(geoip_data = self.get_geoip_data(ipaddress))
      if(geoip_data[:country_code] == 'US')
        self.find_by_abbreviation(geoip_data[:region])
      else
        self.find_by_abbreviation('OUTSIDEUS')
      end
    else
      return nil
    end
  end
  
  def self.get_geoip_data(ipaddress = Settings.request_ip_address)
    if(geoip_data_file = Settings.geoip_data_file)
      if File.exists?(geoip_data_file)
        returnhash = {}
        if(data = GeoIP.new(geoip_data_file).city(ipaddress))
          returnhash[:country_code] = data[2]
          returnhash[:region] = data[6]
          returnhash[:city] = data[7]
          returnhash[:postal_code] = data[8]
          returnhash[:lat] = data[9]
          returnhash[:lon] = data[10]
          returnhash[:tz] = data[13]
          return returnhash
        end
      else
        return nil
      end      
    else
      return nil
    end  
  end
  
  
end
