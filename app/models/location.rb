# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
# 
#  see LICENSE file

class Location < ActiveRecord::Base
  include CacheTools

  # entrytypes
  UNKNOWN = 0
  STATE = 1
  INSULAR = 2
  OUTSIDEUS = 3

  has_many :user_locations
  has_many :users, :through => :user_locations
  has_many :group_locations
  has_many :groups, :through => :group_locations
  has_many :counties
  has_many :users_with_origin, :class_name => "User", :foreign_key => "location_id"
  has_many :questions_with_origin, :class_name => "Question", :foreign_key => "location_id"
  

  scope :states, where(entrytype: STATE)

  def self.find_by_geoip(ipaddress = Settings.request_ip_address,cache_options = {})
    cache_key = self.get_cache_key(__method__,{ipaddress: ipaddress})
    Rails.cache.fetch(cache_key,cache_options) do
      if(geoip_data = self.get_geoip_data(ipaddress))
        if(geoip_data[:country_code] == 'US')
          self.find_by_abbreviation(geoip_data[:region])
        else
          self.find_by_abbreviation('OUTSIDEUS')
        end
      else
        nil
      end
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
  
  def get_all_county
    return County.find_by_location_id_and_name(self.id, 'All')
  end

  def self.in_state_out_metrics_by_year(year,cache_options = {})
    if(!cache_options[:expires_in].present?)
      if(year == Date.today.year)
        cache_options[:expires_in] = 24.hours
      else
        cache_options[:expires_in] = 7.days
      end
    end
    cache_key = self.get_cache_key(__method__,{year: year})
    Rails.cache.fetch(cache_key,cache_options) do
      self._in_state_out_metrics_by_year(year)
    end
  end

  def self.asked_answered_metrics_by_year(year,cache_options = {})
    if(!cache_options[:expires_in].present?)
      if(year == Date.today.year)
        cache_options[:expires_in] = 24.hours
      else
        cache_options[:expires_in] = 7.days
      end
    end
    cache_key = self.get_cache_key(__method__,{year: year})
    Rails.cache.fetch(cache_key,cache_options) do
      self._asked_answered_metrics_by_year(year)
    end
  end  

  def self._in_state_out_metrics_by_year(year)
    in_out_state = {}
    out_state = Question.not_rejected.joins(:question_events => :initiator) \
                .where('users.location_id != questions.location_id') \
                .where("question_events.event_state = #{QuestionEvent::RESOLVED}") \
                .where("DATE_FORMAT(question_events.created_at,'%Y') = #{year}") \
                .group('questions.location_id').count('DISTINCT(questions.id)')

    out_state_experts = Question.not_rejected.joins(:question_events => :initiator) \
                .where('users.location_id != questions.location_id') \
                .where("question_events.event_state = #{QuestionEvent::RESOLVED}") \
                .where("DATE_FORMAT(question_events.created_at,'%Y') = #{year}") \
                .group('questions.location_id').count('DISTINCT(question_events.initiated_by_id)')

    in_state = Question.not_rejected.joins(:question_events => :initiator) \
                .where('users.location_id = questions.location_id') \
                .where("question_events.event_state = #{QuestionEvent::RESOLVED}") \
                .where("DATE_FORMAT(question_events.created_at,'%Y') = #{year}") \
                .group('questions.location_id').count('DISTINCT(questions.id)')

    in_state_experts = Question.not_rejected.joins(:question_events => :initiator) \
                .where('users.location_id = questions.location_id') \
                .where("question_events.event_state = #{QuestionEvent::RESOLVED}") \
                .where("DATE_FORMAT(question_events.created_at,'%Y') = #{year}") \
                .group('questions.location_id').count('DISTINCT(question_events.initiated_by_id)')


    Location.order('entrytype,name').each do |location|
      in_out_state[location] ={:in_state => in_state[location.id] || 0, 
                               :out_state => out_state[location.id] || 0, 
                               :in_state_experts => in_state_experts[location.id] || 0, 
                               :out_state_experts => out_state_experts[location.id] || 0 }
    end

    in_out_state

  end

  def self._asked_answered_metrics_by_year(year)
    asked_answered = {}
    asked    = Question.not_rejected \
               .where("DATE_FORMAT(questions.created_at,'%Y') = #{year}") \
               .group('questions.location_id').count('DISTINCT(questions.id)')

    submitters = Question.not_rejected \
               .where("DATE_FORMAT(questions.created_at,'%Y') = #{year}") \
               .group('questions.location_id').count('DISTINCT(questions.submitter_id)')

    answered = Question.not_rejected.joins(:question_events => :initiator) \
               .where("question_events.event_state = #{QuestionEvent::RESOLVED}") \
               .where("DATE_FORMAT(question_events.created_at,'%Y') = #{year}") \
               .group('questions.location_id').count('DISTINCT(questions.id)')

    experts = QuestionEvent.joins(:initiator).handling_events \
               .where("DATE_FORMAT(question_events.created_at,'%Y') = #{year}") \
               .group('users.location_id').count('DISTINCT(question_events.initiated_by_id)')

    Location.order('entrytype,name').each do |location|
      asked_answered[location] ={:asked => asked[location.id] || 0, 
                                 :submitters => submitters[location.id] || 0, 
                                 :answered => answered[location.id] || 0,
                                 :experts => experts[location.id] || 0 }
    end

    asked_answered

  end



end
