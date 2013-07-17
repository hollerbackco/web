# register routes
module HollerbackApp
  class ApiApp < BaseApp
    post '/register' do
      user = User.new({
        username: params["username"],
        phone:    params["phone"]
      })

      if user.save
        #device = user.device_for(params["device_token"], params["platform"])

        Keen.publish("users:new", {
          memberships: user.conversations.count
        })

        if Sinatra::Base.production?
          Hollerback::SMS.send_message "+13033595357", "#{user.name} #{user.phone_normalized} signed up"
        end

        Hollerback::SMS.send_message user.phone_normalized, "Verification Code: #{user.verification_code}"
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
