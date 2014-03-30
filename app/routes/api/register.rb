# register routes
module HollerbackApp
  class ApiApp < BaseApp
    post '/register' do
      unless ensure_params(:email, :password, :username, :phone)
        return error_json 400, msg: "Missing required params"
      end
      begin
        user = User.find_by_email(params[:email])
        if user and user.verified?
          return error_json 400, msg: "Email is taken"
        end

        if user.present?
          # make sure the passwords match
          user = User.authenticate_with_email(params[:email], params[:password])
          raise ActiveRecord::RecordNotFound if user.blank?
        else
          user = User.new({email: params[:email], password: params[:password]})
        end

        user.phone = params[:phone]
        user.phone_hashed = params[:phone_hashed]
        user.username = params[:username]
        user.set_verification_code

        if user.save
          # send a verification code
          Hollerback::SMS.send_message user.phone_normalized, "Hollerback Code: #{user.verification_code}"

          {
            user: user.reload.as_json
          }.to_json
        else
          error_json 400, for: user
        end
      rescue ActiveRecord::RecordNotFound
        error_json 400, msg: "Email is taken"
      end
    end

    post '/verify' do
      unless ensure_params(:phone, :code)
        return error_json 400, msg: "Missing required params"
      end
      authenticate(:password)

      #authenticate(:password)
      # remove all devices with device_token that is not blank
      if params.key "device_token" and !params["device_token"].blank?
        devices = Device.where("token" => params["device_token"])
        devices.destroy_all
      end

      if params.key? "device_id"
        if device = user.devices.find_by_device_key(params["device_id"])
          device.token = params["device_token"]
          device.save
        end
      end
      if device.blank?
        device = user.device_for(params['device_token'], params['platform'])
      end

      #accept all invites
      Invite.accept_all!(device.user)
      EmailInvite.accept_all!(device.user)

      registrar = UserRegister.new
      registrar.perform(device.user.id)

      {
        access_token: device.access_token,
        user: user.reload.as_json.merge(access_token: device.access_token)
      }.to_json
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
