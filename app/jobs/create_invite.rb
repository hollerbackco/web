class CreateInvite
  include Sidekiq::Worker

  #add the invitations to the user's invites
  def perform(user_id, phones, emails)

    #ensure the user is valid
    user = User.find(user_id)

    return unless user

    if (phones.any?)
      create_phone_invites(user, phones)
    elsif (emails.any?)
      create_email_invites(user, emails)
    end
  end

  def create_email_invites(user, emails)
    p "email invites"
    #reduce the emails to remove existing ones
    emails = emails.reduce([]) do |filtered_emails, email|

      #make sure that the email doesn't belong to an already registered user
      if User.find_by_email(email).blank? && EmailInvite.find_by_email(email).blank?
        filtered_emails << email
      end

      filtered_emails
    end

    return if emails.blank?

    #great we now have a list of fitlered emails
    emails.each do |email|
      user.email_invites.create(:email => email, :accepted => false)
    end

    data = { invites: emails }
    MetricsPublisher.publish(user, "users:invite:explicit", data)
  end

  def create_phone_invites(user, invites)


    #ensure that the values passed in aren't actual users
    existing_users = User.where('phone IN (?)', invites)
    unless existing_users.empty?
      invites = invites.reduce([]) do |filtered_invites, invite|

        remove = false
        existing_users.each do |existing_user|
          if existing_user.phone == invite
            remove = true
            break
          end
        end

        filtered_invites << invite unless remove
        filtered_invites
      end
    end

    return if invites.empty?

    #create the invitations
    User.transaction do
      actual_invites = []
      invites.each do |invited_phone|
        unless user.invites.where(:phone => invited_phone).any?
          user.invites.create(:inviter => user, :phone => invited_phone)
          actual_invites << invited_phone
        end
      end

      return if actual_invites.blank?

      data = {
          invites: actual_invites
      }
      MetricsPublisher.publish(user, "users:invite:explicit", data)
    end
  end

end