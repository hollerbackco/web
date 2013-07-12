module HollerbackApp
  class ApiApp < BaseApp
    route :get, :post, '/contacts/check' do
      numbers = params["numbers"]
      if numbers.is_a? String
        numbers = numbers.split(",")
      end

      contacts =  Hollerback::ContactChecker.new(numbers, current_user).contacts

      #TODO remove this after launch
      user = User.where(email: "williamldennis@gmail.com").first
      contacts = contacts - [user]

      if params["first"]
        user.name = "Will Dennis - Cofounder of Hollerback"
        contacts << user if user
      end

      success_json data: contacts
    end
  end
end
