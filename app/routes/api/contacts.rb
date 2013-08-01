module HollerbackApp
  class ApiApp < BaseApp
    route :get, :post, '/contacts/check' do
      contacts = if params.key? "numbers"
        numbers = params["numbers"]
        if numbers.is_a? String
          numbers = numbers.split(",")
        end
        contacts =  Hollerback::ContactChecker.new.find_by_phone(numbers)
      else
        unless ensure_params(:c)
          return error_json 400, msg: "missing required params"
        end

        if params.key? "access_token"
          login(:api_token)
          contacts = prepare_contacts(params["c"])
          hashed_numbers = prepare_only_hashed_numbers(params["c"])

          #UpdateContactBook.perform_async(current_user.id, contacts)
          contact_book = Hollerback::ContactBook.new(current_user)
          contact_book.update(contacts)
          contacts = contact_book.contacts_on_hollerback
        else
          hashed_numbers = prepare_only_hashed_numbers(params["c"])
          contacts =  Hollerback::ContactChecker.new.find_by_hashed_phone(hashed_numbers)
        end

        contacts
      end

      success_json data: contacts.as_json
    end


    helpers do
      def prepare_only_hashed_numbers(contact_params)
        contact_params.map { |c| c["p"].split(",") }.flatten
      end

      def prepare_contacts(contact_params)
        contact_params.map do |c|
          name = c["n"]
          numbers = c["p"].split(",")
          numbers.map do |number|
            {"name" => name, "phone" => number}
          end
        end.flatten
      end
    end
  end
end
