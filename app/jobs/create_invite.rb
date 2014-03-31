class CreateInvite
  include Sidekiq::Worker

  #add the invitations to the user's invites
  def perform(user_id, phones, emails)

    #ensure the user is valid
    user = User.find(user_id)

    return unless user

    if (phones.any?)
      create_phone_invites(user, phones)
    end
    if (emails.any?)
      create_email_invites(user, emails)
    end
  end

  def create_email_invites(user, emails)

    return if emails.blank?

    filtered_emails = []

    #create an email invite
    emails.each do |email|
      if User.find_by_email(email).blank?
        if EmailInvite.find_by_email(email).blank?
          filtered_emails << email
        end

        if user.email_invites.find_by_email(email).blank? # create an invite only if the invitation doesn't exist for that user
          user.email_invites.create(:email => email, :accepted => false)
        end
      end
    end

    already_invited = emails - filtered_emails

    #track that an invite was made, but not necessarily one where it's a new invite
    data = {
          invites: filtered_emails,
          already_invited: already_invited
    } #don't count any email that is already registered
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

        if(Invite.where(:phone => invited_phone).blank?) #make sure that we only count invites that aren't already invited
          actual_invites << invited_phone
        end

        #create the invite only if the user hasn't already invited this person
        unless user.invites.where(:phone => invited_phone).any?
          user.invites.create(:inviter => user, :phone => invited_phone)
        end
      end
      p "invites #{actual_invites} + already: " + (invites - actual_invites).to_s
      #if the user has already been invited, don't track it as a new invitation
      data = {
          invites: actual_invites,
          already_invited: invites - actual_invites
      }
      MetricsPublisher.publish(user, "users:invite:explicit", data)
    end
  end

end
