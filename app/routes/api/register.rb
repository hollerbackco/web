# register routes
module HollerbackApp
  class ApiApp < BaseApp
    post '/register' do
      user = User.where({
        email:    params["email"]
      }).first_or_initialize

      if user.persisted? and user.verified?
        return error_json(400, msg: "already signed up")
      end

      first_try = user.new_record?

      user.phone = params["phone"]
      user.username = params["username"]
      user.password = params["password"]
      user.set_verification_code

      if user.save
        if first_try
          Invite.accept_all!(user)
          UserRegister.perform_async(user.id)
        end

        {
          user: user.reload.as_json
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
