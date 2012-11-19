# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class PublicMailer < ActionMailer::Base
  helper ApplicationHelper
  default_url_options[:host] = Settings.urlwriter_host
  default from: "aae-notify@extension.org"
  default bcc: "systemsmirror@extension.org"
  helper_method :ssl_root_url, :ssl_webmail_logo
  
  def public_expert_response(options = {})
    @user = options[:user]
    @expert = options[:expert]
    @question = options[:question]
    @subject = "[eXtension Question:#{@question.id}] Your question has been responded to by one of our experts."
    @response = @question.responses.last
    
    @will_cache_email = options[:cache_email].nil? ? true : options[:cache_email]
    
    if(!@user.email.blank?)
      if(@will_cache_email)
        # create a cached mail object that can be used for "view this in a browser" within
        # the rendered email.
        @mailer_cache = MailerCache.create(user: @user, cacheable: @group)
      end
      
      return_email = mail(to: @user.email, subject: @subject)
      
      if(@mailer_cache)
        # now that we have the rendered email - update the cached mail object
        @mailer_cache.update_attribute(:markup, return_email.body.to_s)
      end
    end

    # the email if we got it
    return_email
  end
    
  def public_submission_acknowledgement(options = {})
      @user = options[:user]
      @question = options[:question]
      @subject = "[eXtension Question:#{@question.id}] Thank you for your question submission."
      @will_cache_email = options[:cache_email].nil? ? true : options[:cache_email]

      if(!@user.email.blank?)
        if(@will_cache_email)
          # create a cached mail object that can be used for "view this in a browser" within
          # the rendered email.
          @mailer_cache = MailerCache.create(user: @user, cacheable: @group)
        end

        return_email = mail(to: @user.email, subject: @subject)

        if(@mailer_cache)
          # now that we have the rendered email - update the cached mail object
          @mailer_cache.update_attribute(:markup, return_email.body.to_s)
        end
      end
    
    # the email if we got it
    return_email
  end

  def public_evaluation_request(options = {})
    @user = options[:user]
    @question = options[:question]
    @example_survey = options[:example_survey]

    @subject = "[eXtension Question:#{@question.id}] Tell us about your experience."
    @will_cache_email = options[:cache_email].nil? ? true : options[:cache_email]

    if(!@user.email.blank?)
      if(@will_cache_email)
        # create a cached mail object that can be used for "view this in a browser" within
        # the rendered email.
        @mailer_cache = MailerCache.create(user: @user, cacheable: @group)
      end

      return_email = mail(to: @user.email, subject: @subject)

      if(@mailer_cache)
        # now that we have the rendered email - update the cached mail object
        @mailer_cache.update_attribute(:markup, return_email.body.to_s)
      end
    end
    
    # the email if we got it
    return_email
  end

  def ssl_root_url
    if(Settings.app_location != 'localdev')
      root_url(protocol: 'https')
    else
      root_url
    end
  end

  def ssl_webmail_logo
    parameters = {mailer_cache_id: @mailer_cache.id, format: 'png'}
    if(Settings.app_location != 'localdev')
      webmail_logo_url(parameters.merge({protocol: 'https'}))
    else
      webmail_logo_url(parameters)
    end
  end

end
