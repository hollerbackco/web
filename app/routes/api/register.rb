# register routes
module HollerbackApp
  class ApiApp < BaseApp
    post '/register' do
      user = User.new({
        username: params["username"],
        phone:    params["phone"]
      })

      if user.save
        UserRegister.perform_async(user.id)

        {
          user: user.as_json
        }.to_json
      else
        error_json 400, for: user
      end
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
