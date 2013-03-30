module Sinatra
  module CoreHelpers
    # checks the params hash for a single argument as both !nil and !empty
    def ensure_param(arg)
      params[arg.to_sym].present?
    end

    # checks an array of params from the params hash
    def ensure_params(*args)
      return catch(:truthy) {
        args.each do |arg|
          throw(:truthy, false) unless ensure_param(arg)
        end

        throw(:truthy, true)
      }
    end

    def conversation_json(conversation)
      conversation.as_json(root: false).merge(
        unread_count: conversation.videos.unread_by(current_user).count,
        members: conversation.members,
        invites: conversation.invites,
        videos: conversation.videos.with_read_marks_for(current_user)
      )
    end

    def error_json(error_code, msg)
      {
        meta: {
          code: error_code,
          errors: msg
        }
      }.to_json
    end
  end

  helpers CoreHelpers
end
