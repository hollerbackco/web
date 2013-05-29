# register routes
module HollerbackApp
  class ApiApp < BaseApp
    post '/register' do
      user = User.new({
        email:    params[:email],
        name:     params[:name],
        password: params[:password],
        password_confirmation: params[:password],
        phone: params[:phone]
      })

      if params.key? :platform and params.key? :device_token
        user.devices.build({
          :platform => params[:platform],
          :token => params[:device_token]
        })
      elsif params.key? :device_token
        user.device_token = params[:device_token]
      end

      if user.save
        Keen.publish("users:new", {
          memberships: user.conversations.count
        })

        #Hollerback::SMS.send_message user.phone_normalized, "Verification Code: #{user.verification_code}"
        if Sinatra::Base.production?
          Hollerback::SMS.send_message "+13033595357", "#{user.name} #{user.phone_normalized} signed up"
        end
        {
          access_token: user.access_token,
          user: user
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
