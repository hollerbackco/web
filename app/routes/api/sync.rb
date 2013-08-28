module HollerbackApp
  class ApiApp < BaseApp
    get '/me/sync' do
      updated_at = Time.parse(params[:updated_at]) if params[:updated_at]

      syncable = [Membership, Message]

      sync_objects = []

      syncable.each do |collection|
        objects = collection.sync_objects(user: current_user, since: updated_at)

        sync_objects = sync_objects.concat(objects)
      end

      success_json data: sync_objects.as_json
    end
  end
end
