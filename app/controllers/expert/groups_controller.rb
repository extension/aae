# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class Expert::GroupsController < ApplicationController
  layout 'expert'
  before_filter :authenticate_user!
  before_filter :require_exid
  
  def index
    @my_groups = current_user.group_memberships
    @groups = Group.paginate(:page => params[:page]).order(:name)
  end
  
  def show
    @group = Group.find(params[:id])
    if !@group 
      return record_not_found
    end
    
    @open_questions = @group.open_questions
    @group_members = @group.joined.limit(5)
    @group_tags = @group.tags
  end
  
  def members
    @group = Group.find(params[:id])
    @group_members = @group.joined
  end
  
  def questions_by_tag
    @group = Group.find_by_id(params[:group_id])
    @tag = Tag.find_by_id(params[:tag_id])
    
    return record_not_found if (!@group || !@tag)
    
    @questions = Question.from_group(@group.id).tagged_with(@tag.id).order("questions.status_state ASC")
  end
  
  
  
end