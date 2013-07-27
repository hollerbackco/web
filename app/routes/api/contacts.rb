module HollerbackApp
  class ApiApp < BaseApp
    route :get, :post, '/contacts/check' do
      contacts = if params.key? "numbers"
        numbers = params["numbers"]
        if numbers.is_a? String
          numbers = numbers.split(",")
        end
        contacts =  Hollerback::ContactChecker.new(numbers).contacts

        #TODO remove this after launch
        user = User.where(email: "williamldennis@gmail.com").first
        contacts = contacts - [user]

        if params["first"] and user
          user.name = "Will Dennis - Cofounder of Hollerback"
          contacts << user if user
        end
        contacts
      else
        unless ensure_params(:c)
          return error_json 400, msg: "missing required params"
        end
        contacts = prepare_contacts(params["c"])
        contact_book = Hollerback::ContactBook.new(current_user)
        contact_book.update(contacts)
        contacts = contact_book.contacts_on_hollerback
      end

      success_json data: contacts.as_json
    end


    helpers do
      def prepare_contacts(contact_params)
        contact_params.map do |c|
          name = c["name"]
          numbers = c["phone"].split(",")
          numbers.map do |number|
            {"name" => name, "phone" => number}
          end
        end.flatten
      end
    end
  end
end
