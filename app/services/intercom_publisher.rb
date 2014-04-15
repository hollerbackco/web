class IntercomPublisher
  include Sidekiq::Worker

  class Method
    CREATE = "create"
    UPDATE = "update"
  end


  def perform(user_id, method, user_agent)

    user = User.find(user_id)
    case method
      when Method::CREATE
        create_user(user, user_agent)
      when Method::UPDATE
        update_user(user, user_agent)
    end

  end

  def create_user(user, user_agent)
    payload = get_user_payload(user, user_agent)
    Intercom::User.create(payload)
  end

  def update_user(user, user_agent)
<<<<<<< HEAD
    payload = get_user_payload(user, user_agent)
    Intercom::User.create(payload)
    impression(user, user_agent)
=======
    impression(user, user_agent)
    payload = get_user_payload(user, user_agent)
    Intercom::User.create(payload)
>>>>>>> bb8b8e3... intercom support
  end

  def impression(user, user_agent)
    Intercom::Impression.create(:email => user.email, :user_agent => user_agent)
  end

  def get_user_payload(user, user_agent)
    {
        :email => user.email,
        :created_at => user.created_at.to_f,
        :last_seen_user_agent => user_agent,
        :last_request_at => user.last_active_at.to_f,
        :custom_data => {
            :video_count => user.videos.count,
            :text_count => user.texts.count,
            :invite_count => user.invites.count,
            :cohort => user.cohort,
            :last_app_version => user.last_app_version
        }
    }
  end

end