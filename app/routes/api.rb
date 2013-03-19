module HollerbackApp
  class ApiApp < BaseApp
    before do
      content_type 'application/json'
    end
  end
end
