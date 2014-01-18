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
      friend = User.find_by_username(params[:username])
      if friend
        friendship = current_user.friendships.create(friend_id: friend.id)
        p current_user.reload.friends.to_sql
        success_json data: current_user.friends
      else
        success_json data: nil
      end
    end

    post '/me/friends/remove' do
      friend = User.find_by_username(params[:username])
      current_user.friends
    end
  end
end
