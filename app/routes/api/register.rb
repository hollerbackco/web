# register routes
module HollerbackApp
  class ApiApp < BaseApp
    post '/register' do
      user = User.new({
        email:    params[:email],
        name:     params[:name],
        password: params[:password],
        password_confirmation: params[:password],
        phone: params[:phone],
        device_token: params[:device_token]
      })

      if user.save
        #Hollerback::SMS.send_message user.phone_normalized, "Verification Code: #{user.verification_code}"
        {
          access_token: user.access_token,
          user: user
        }.to_json
      else
        {
          meta: {
            code: 400,
            errors: user.errors
          }
        }.to_json
      end
    end

    post '/waitlist' do
      waitlister = Waitlister.new(email: params[:email])

      if waitlister.save
        {
          data: waitlister.to_json
        }
      else
        error_json 400, waitlister.errors
      end
    end
  end
end
