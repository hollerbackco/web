module HollerbackApp
  class ApiApp < BaseApp
    get '/me/sync' do
      last_sync_at = Time.now
      updated_at = Time.parse(params[:updated_at]) if params[:updated_at]

      syncable = [Membership, Message]

      sync_objects = []

      syncable.each do |collection|
        objects = collection.sync_objects(user: current_user, since: updated_at)

        sync_objects = sync_objects.concat(objects)
      end

      data = success_json(
        meta: {
          last_sync_at: last_sync_at
        },
        data: sync_objects.as_json
      )
      data
    end
  end
end
