# Here's the story: Since Steve totally sucks at writing validations, we have a
# bunch of users with screwed up usernames, so we also have a bunch of stuff
# that handles those cases. In a few weeks we should be able to clean out this
# entire file. Woohoo!

class Rstatus
  # EMPTY USERNAME HANDLING - quick and dirty
  before do
    @error_bar = ""
    if current_user && (current_user.username.nil? or current_user.username.empty? or !current_user.username.match(/profile.php/).nil?)
      @error_bar = haml :"login/_username_error", :layout => false
    end
  end

  # Allows a user to reset their username. Currently only allows users that
  # are not registered, users without a username and facebook users with the
  # screwed up username
  get '/reset-username' do
    unless current_user.nil? || current_user.username.empty? || current_user.username.match(/profile.php/)
      redirect "/"
    end

    haml :"login/reset_username"
  end

  post '/reset-username' do
    exists = User.first :username => params[:username]
    if !params[:username].nil? && !params[:username].empty? && exists.nil?
      if current_user.reset_username(params)
        flash[:notice] = "Thank you for updating your username"
      else
        flash[:notice] = "Your username could not be updated"
      end
      redirect "/"
    else
      flash[:notice] = "Sorry, that username has already been taken or is not valid. Please try again."
      haml :"login/reset_username"
    end
  end

  get '/reset_password' do
    if not logged_in?
      redirect "/forgot_password"
    end
  end

  # Public reset password page, accessible via a valid token. Tokens are only
  # valid for 2 days and are unique to that user. The user is found using the
  # token and the reset password page is rendered
  get '/reset_password/:token' do
    user = User.first(:perishable_token => params[:token])
    if user.nil? || user.password_reset_sent.to_time < 2.days.ago
      flash[:notice] = "Your link is no longer valid, please request a new one."
      redirect "/forgot_password"
    else
      @token = params[:token]
      @user = user
      haml :"login/password_reset"
    end
  end

  # Submitted passwords are checked for length and confirmation. If the user
  # does not have an email address they are required to provide one. Once the
  # password has been reset the user is redirected to /
  post '/reset_password' do
    user = nil

    if params[:token]
      user = User.first(:perishable_token => params[:token])
      if user and user.password_reset_sent.to_time < 2.days.ago
        user = nil
      end
    end

    unless user.nil?
      # XXX: yes, this is a code smell

      if params[:password].size == 0
        flash[:notice] = "Password must be present"
        redirect "/reset_password/#{params[:token]}"
        return
      end

      if params[:password] != params[:password_confirm]
        flash[:notice] = "Passwords do not match"
        redirect "/reset_password/#{params[:token]}"
        return
      end

      if user.email.nil?
        if params[:email].empty?
          flash[:notice] = "Email must be provided"
          redirect "/reset_password/#{params[:token]}"
          return
        else
          user.email = params[:email]
        end
      end

      user.password = params[:password]
      user.save
      flash[:notice] = "Password successfully set"
      redirect "/"
    else
      redirect "/forgot_password"
    end
  end
end
