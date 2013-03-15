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
        {
          access_token: user.access_token,
          user: current_user
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
  end
end
