# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class WebmailController < ApplicationController

  def view
    if(mailer_cache = MailerCache.find_by_hashvalue(params[:hashvalue]))
      inlined_content = InlineStyle.process(mailer_cache.markup,ignore_linked_stylesheets: true)
      render(:text => inlined_content, :layout => false)
    else
      return render(template: "webmail/missing_view")
    end
  end
    
end
