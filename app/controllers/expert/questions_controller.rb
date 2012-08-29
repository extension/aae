# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class Expert::QuestionsController < ApplicationController
  layout 'expert'
  before_filter :authenticate_user!
  before_filter :require_exid
  
  def show
    @question = Question.find_by_id(params[:id])
    @question_responses = @question.responses
    @fake_related = Question.find(:all, :limit => 3, :offset => rand(Question.count))

    ga_tracking = []
    
    if @question.tags.length > 0
      ga_tracking = ["|tags"] + @question.tags.map(&:name)
    end
    
    question_resolves_with_resolver = @question.question_events.where('event_state = 2').includes(:initiator)
    
    if question_resolves_with_resolver.length > 0
      ga_tracking += ["|experts"] + question_resolves_with_resolver.map{|qe| qe.initiator.login}.uniq
    end
    
    if @question.assigned_group
      ga_tracking += ["|group"] + [@question.assigned_group.name]
    end
    
    if ga_tracking.length > 0
      flash.now[:googleanalytics] = expert_question_url(@question.id) + "?" + ga_tracking.join(",")
    end
  end
  
  def assign
    if !params[:id]
      flash[:failure] = "You must select a question to assign."
      return redirect_to expert_questions_url
    end
    
    @question = Question.find_by_id(params[:id])
        
    if !@question
      flash[:failure] = "Invalid question."
      return redirect_to expert_questions_url
    end
    
    if !params[:assignee_login]
      flash[:failure] = "You must select a user to reassign."
      redirect_to expert_question_url(@question)
      return
    end
      
    user = User.where(:login => params[:assignee_login])
      
    if !user || user.retired?
      !user ? err_msg = "User does not exist." : err_msg = "User is retired from the system"
      flash[:failure] = err_msg
      return redirect_to expert_question_url(@question)
    end
      
    if !user.aae_responder && current_user.id != user.id
      flash[:failure] = "This user has elected not to receive questions."
      return redirect_to expert_question_url(@question)  
    end
      
    params[:assign_comment].present? ? assign_comment = params[:assign_comment] : assign_comment = nil
        
    @question.assign_to(user, current_user, assign_comment)
    # re-open the question if it's reassigned after resolution
    if @question.status_state == Question::STATUS_RESOLVED || @question.status_state == Question::STATUS_NO_ANSWER
      @question.update_attributes(:status => Question::SUBMITTED_TEXT, :status_state => Question::STATUS_SUBMITTED)
      QuestionEvent.log_reopen(@question, user, current_user, assign_comment)
    end
      
    redirect_to expert_question_url(@question)
  end
  
  def assign_to_wrangler
    if request.post? and params[:squid]
      submitted_question = SubmittedQuestion.find_by_id(params[:squid])
      recipient = submitted_question.assign_to_question_wrangler(@currentuser)
      # re-open the question if it's reassigned after resolution
      if submitted_question.status_state == SubmittedQuestion::STATUS_RESOLVED or submitted_question.status_state == SubmittedQuestion::STATUS_NO_ANSWER
        submitted_question.update_attributes(:status => SubmittedQuestion::SUBMITTED_TEXT, :status_state => SubmittedQuestion::STATUS_SUBMITTED)
        SubmittedQuestionEvent.log_reopen(submitted_question, recipient, @currentuser, SubmittedQuestion::WRANGLER_REASSIGN_COMMENT)
      end
      
    else
      do_404
      return
    end
    
    redirect_to :action => :index, :id => submitted_question.id
  end
  
  def add_tag
    @question = Question.find_by_id(params[:id])
    @tag = @question.set_tag(params[:tag])
    if @tag == false
      render :nothing => true
    end
  end
  
  def remove_tag
    @question = Question.find_by_id(params[:id])
    tag = Tag.find(params[:tag_id])
    @question.tags.delete(tag)
  end
  
end
