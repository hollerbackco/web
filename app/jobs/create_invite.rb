class CreateInvite
  include Sidekiq::Worker

  #add the invitations to the user's invites
  def perform(user_id, invites)
    user = User.find(user_id)

    return unless user

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
      invites.each do |invited_phone|
        unless user.invites.where(:phone => invited_phone).any?
          user.invites.create(:inviter => user, :phone => invited_phone)
          data = {
              invited_phone: invited_phone
          }
          MetricsPublisher.publish(user, "users:invite:explicit", data)
        end
      end
    end

  end

end