module HollerbackApp
  class Register < BaseApp
    post '/' do
      user = User.new({
        email:    params[:email],
        name:     params[:name],
        password: params[:password],
        password_confirmation: params[:password],
        phone: params[:phone]
      })

      if user.save
        {access_token: user.access_token}.to_json
      else
        {errors: user.errors.full_messages}.to_json
      end
    end
  end
end
