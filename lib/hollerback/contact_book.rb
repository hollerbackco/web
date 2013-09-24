module Hollerback
  class ContactBook
    attr_accessor :user, :contacts, :contact_ids

    def initialize(user)
      @user = user
      @contacts = user.contacts
      @contact_ids = []
    end

    def update(obj=[])
      Contact.transaction do
        obj.each do |contact_params|
          name = contact_params["name"]
          phone = contact_params["phone"]

          contact = Contact.where(user_id: user.id, phone_hashed: phone).first_or_create

          contact.name = name
          contact.save
          self.contact_ids << contact.id
        end
      end
    end

    def contacts_on_hollerback
      contacts = Contact.joins(:aliased_user).where("contacts.id" => self.contact_ids).where("contacts.user_id = ?", user.id)
    end

  end
end
