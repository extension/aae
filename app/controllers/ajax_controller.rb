# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class AjaxController < ApplicationController
  def tags
    if params[:term]
      search_term = params[:term]
      tags = Tag.where("name like ?", "%#{params[:term]}%").limit(12)
    else
      tags = Tag.order('created_at DESC').limit(12)
    end
    list = []
    tags.each do |t|
      list <<  Hash[ id: t.id, label: t.name, name: t.name] if t.name != search_term
    end
    list.unshift(Hash[id: nil, label: search_term, name: search_term])
    render json: list
  end

  def experts
    if params[:term]
      search_term = params[:term]
      
      groups_starting_with = Group.where(group_active: true).pattern_search(params[:term], "prefix").limit(9)
      groups_including = Group.where(group_active: true).pattern_search(params[:term]).limit(9)
      groups = (groups_starting_with + groups_including).uniq.take(9)
      
      experts_starting_with = User.exid_holder.active.not_blocked.pattern_search(params[:term], "prefix").limit(18 - groups.length)
      experts_including = User.exid_holder.active.not_blocked.pattern_search(params[:term]).limit(18 - groups.length)
      experts = (experts_starting_with + experts_including).uniq.take(9)
    else
      groups = Group.where(group_active: true).order('created_at DESC').limit(6)
      experts = User.exid_holder.active.not_blocked.order('created_at DESC').limit(6)
    end

    combined_array = groups + experts

    list = combined_array.map {|e| Hash[ id: e.id, label: e.class.name == "User" ? ("#{view_context.get_avatar_for_user(e, :thumb).html_safe}" + " #{e.name} #{e.title.present? ? '<br />' + e.title : ''}<br />" + (e.county.present? ? "#{e.county.name}," : "") + (e.location.present? ? "#{e.location.name}" : "")) : ("#{view_context.get_avatar_for_group(e, :thumb, true).html_safe}" + " #{e.name}"), name: e.name, value: e.name, class_type: e.class.name]}
    render json: list
  end

  def groups
    if params[:term]
      search_term = params[:term]
      
      groups_starting_with = Group.where(group_active: true).pattern_search(params[:term], "prefix").limit(12)
      groups_including = Group.where(group_active: true).pattern_search(params[:term]).limit(12)
      groups = (groups_starting_with + groups_including).uniq.take(12)
    else
      groups = Group.where(group_active: true).order('created_at DESC').limit(12)
    end
    list = groups.map {|g| Hash[ id: g.id, label: g.name, name: g.name]}
    render json: list
  end

  def counties
    if params[:term]
      like= "%".concat(params[:term].concat("%"))
      counties = County.where("name like ?", like).where(:location_id => params[:location_id])
    else
      counties = County.where(:location_id => params[:location_id])
    end
    list = counties.map {|c| Hash[ id: c.id, label: c.name, name: c.name]}
    render json: list
  end


  def show_location
    case params[:object_type]
      when "group"    then @object = Group.find_by_id(params[:object_id])
      when "user"     then @object = User.find_by_id(params[:object_id])
    end
    location = Location.find(params[:requested_location])
    render :partial => 'show_location', :locals => {:location => location}
  end


  def edit_location
    case params[:object_type]
      when "group"    then @object = Group.find_by_id(params[:object_id])
      when "user"     then @object = User.find_by_id(params[:object_id])
    end
    location = Location.find(params[:requested_location])
    render :partial => 'ajax/edit_location', :locals => {:location => location}
  end


  def add_county
    case params[:object_type]
      when "group"    then @object = Group.find_by_id(params[:object_id])
      when "user"     then @object = User.find_by_id(params[:object_id])
    end
    @county = County.find(params[:requested_county])

    if !@object.expertise_counties.include?(@county)
      @object.expertise_counties << @county
      if !@object.expertise_locations.include?(@county.location)
        @object.expertise_locations << @county.location
      end
      @object.save
    end
  end


  def add_location
    case params[:object_type]
      when "group"    then @object = Group.find_by_id(params[:object_id])
      when "user"     then @object = User.find_by_id(params[:object_id])
    end
    location = Location.find(params[:requested_location])
    @object.expertise_counties.where("location_id = ?", params[:requested_location]).each do |c|
      @object.expertise_counties.delete(c)
    end
    if !@object.expertise_locations.include?(location)
      @object.expertise_locations << location
      @object.save
    end
  end


  def remove_location
    case params[:object_type]
      when "group"    then @object = Group.find_by_id(params[:object_id])
      when "user"     then @object = User.find_by_id(params[:object_id])
    end
    location = Location.find(params[:location_id])
    @object.expertise_counties.where("location_id = ?", params[:location_id]).each do |c|
      @object.expertise_counties.delete(c)
    end
    @object.expertise_locations.delete(location)
  end


  def remove_county
    case params[:object_type]
      when "group"    then @object = Group.find_by_id(params[:object_id])
      when "user"     then @object = User.find_by_id(params[:object_id])
    end
    county = County.find(params[:county_id])
    @object.expertise_counties.delete(county)
  end

end
