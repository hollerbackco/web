module HollerbackApp
  class WebApp < BaseApp
    def http_authorized?
      @auth ||=  Rack::Auth::Basic::Request.new(request.env)
      @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == [ENV["ADMIN_USERNAME"],ENV["ADMIN_PASSWORD"]]
    end

    def http_protected
      unless http_authorized?
        response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
        throw(:halt, [401, "Oops... we need your login name & password\n"])
      end
    end

    before '/madmin*' do
      http_protected
    end

    get '/madmin' do
      haml "admin/index.haml"
    end

  end
end
