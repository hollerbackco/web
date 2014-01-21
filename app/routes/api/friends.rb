module HollerbackApp
  class ApiApp < BaseApp

    helpers do
      def friend_objects_for_user(friendships, user)
        friendships.map do |friendship|
          friend = friendship.friend
          {
            id: friend.id,
            username: friend.username,
            name: friend.also_known_as(for: user),
            last_sent_at: friendship.updated_at
          }
        end
      end
    end

    get '/me/friends' do
      recent_friendships = current_user.friendships.order("updated_at DESC").limit(3)
      friendships = current_user.friendships

      data = {
        recent_friends: friend_objects_for_user(recent_friendships, current_user),
        friends: friend_objects_for_user(friendships, current_user)
      }

      success_json data: data.as_json
    end

    post '/me/friends/add' do
      if params[:username] and params[:username].is_a? String
        usernames = [params[:username]]
      end

      friends = User.where(:username => usernames)
      if friends.any?
        friendships = friends.map do |friend|
          current_user.friendships.where(friend_id: friend.id).first_or_create
        end

        success_json data: friend_objects_for_user(friendships, current_user)
      else
        success_json data: []
      end
    end

    post '/me/friends/remove' do
      friend = User.find_by_username(params[:username])
      current_user.friends

      success_json data: nil
    end
  end
end
