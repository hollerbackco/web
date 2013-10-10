# register routes
module HollerbackApp
  class ApiApp < BaseApp
    post '/register' do
      user = User.new({
        username: params["username"],
        phone:    params["phone"]
      })

      if email = params["email"]
        user.email = email
      end

      if password = params["password"]
        user.password = password
      end

      if user.save
        Invite.accept_all!(user)
        UserRegister.perform_async(user.id)

        {
          user: user.as_json
        }.to_json
      else
        error_json 400, for: user
      end
    end

    post '/email/available' do
      free = User.find_by_email(params[:email]).blank?

      success_json data: free
    end

    post '/waitlist' do
      waitlister = Waitlister.new(email: params[:email])

      if waitlister.save
        {
          data: waitlister.to_json
        }
      else
        error_json 400, msg: waitlister.errors
      end
    end
  end
end
