namespace :email do
  desc "email existing userbase and let them know that a new beta version is available in the appstore"
  task :users_app_available do |t|

    emailed_list = []
    File.open('public/assets/emailed_list.txt').each do |line|
      emailed_list << line.strip.downcase
    end

    User.all.each do |user|

      if emailed_list.include?(user.email.downcase)
        next
      end

      begin
        p "#{user.email}"
        Mail.deliver do
          to user.email
          from 'no-reply@hollerback.co'
          subject "hello from hollerback"

          body File.read('public/assets/update_available_email_body.txt')

        end
      rescue Exception => ex
        Honeybadger.notify(ex, {:message => "couldn't send email to #{user.email}"})
      end
    end
  end
end