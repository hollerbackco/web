module HollerbackApp
  class ApiApp < BaseApp

    helpers do
      def friend_objects_for_user(friends, user)
        friends.map do |friend|
          {
            id: friend.id,
            username: friend.username,
            name: friend.also_known_as(for: user)
          }
        end
      end
    end

    get '/me/friends' do
      friends = current_user.friends

      data = {
        recent_friends: [],
        friends: friend_objects_for_user(friends, current_user)
      }

      success_json data: data.as_json
    end

    post '/me/friends/add' do
      if params[:username] and params[:username].is_a? String
        usernames = [params[:username]]
      end

      friends = User.where(:username => usernames)
      if friends.any?
        for friend in friends
          current_user.friendships.where(friend_id: friend.id).first_or_create
        end

        success_json data: friend_objects_for_user(friends, current_user)
      else
        success_json data: []
      end
    end

    post '/me/friends/remove' do
      friend = User.find_by_username(params[:username])
      current_user.friends
    end
  end
end
