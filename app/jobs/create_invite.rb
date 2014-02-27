
class CreateInvite
  include Sidekiq::Worker

  #add the invitations to the user's invites
  def perform(user_id, invites)
    logger.debug "executing invite task"
    user = User.find(user_id)

    return unless user

    User.transaction do
      invites.each do |invited_phone|
        unless user.invites.where(:phone => invited_phone).any?
          user.invites.create(:inviter => user, :phone => invited_phone)
          data = {
              invited_phone: invited_phone
          }
          logger.debug "created invite " + invited_phone + " for " + user.username
          MetricsPublisher.publish(user, "users:invite:explicit", data)
        end
      end
    end

  end

end