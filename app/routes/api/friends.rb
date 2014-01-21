module HollerbackApp
  class ApiApp < BaseApp
    get '/me/friends' do
      friends = current_user.friends

      data = {
        recent_friends: [],
        friends: friends
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
        success_json data: friends.as_json
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
