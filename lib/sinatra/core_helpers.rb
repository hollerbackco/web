module Sinatra
  module CoreHelpers
    def t(*args)
      I18n.t(*args)
    end

    # checks the params hash for a single argument as both !nil and !empty
    def ensure_param(arg)
      params[arg.to_s].present?
    end

    # checks an array of params from the params hash
    def ensure_params(*args)
      return catch(:truthy) {
        args.each do |arg|
          unless ensure_param arg
            p "request error: missing param \"#{arg}\""
            throw(:truthy, false)
          end
        end

        throw(:truthy, true)
      }
    end

    def conversation_json(conversation, updated_at=nil)
      cache_key = "user/#{current_user.id}/conversations/#{conversation.id}-#{conversation.updated_at}"

      #HollerbackApp::BaseApp.settings.cache.fetch(cache_key, 1.hour) do
        obj = conversation.as_json(root: false).merge({
          "unread_count" => conversation.videos_for(current_user).unread_by(current_user).count,
          "name" => conversation.name(current_user),
          "members" => conversation.members.as_json,
          "invites" => conversation.invites.as_json,
          "is_group" => conversation.group?
        })

        scope = conversation.videos_for(current_user)
        scope = scope.limit(10)
        unless updated_at.nil?
          scope = scope.where("videos.updated_at > ?", updated_at)
        end

        obj["videos"] = scope.map do |video|
          video.as_json_for_user(current_user)
        end

        if conversation.videos.any?
          video = conversation.videos_for(current_user).first
          obj["most_recent_video_url"] =  video.url
          obj["most_recent_thumb_url"] =  video.thumb_url
        end

        obj
      #end
    end

    def success_json(opts={})
      data = opts.delete(:data)
      meta = {code: 200}
      if meta_add = opts.delete(:meta)
        meta = meta.merge meta_add
      end

      {
        meta: {
          code: 200
        },
        data: data
      }.to_json
    end

    def error_json(error_code, options = {})
      options = options.symbolize_keys

      return unless error_code

      ar_object = options.delete :for
      if ar_object.is_a? ActiveRecord::Base
        msg = ar_object.errors.full_messages.join(", ")
        errors = ar_object.errors.full_messages
      end

      msg = options.delete(:msg) || msg || "error"
      errors = options.delete(:errors) || errors || [msg]

      status error_code
      {
        meta: {
          code: error_code,
          msg: msg,
          errors: errors
        }
      }.to_json
    end
  end

  helpers CoreHelpers
end
