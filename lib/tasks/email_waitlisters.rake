namespace :email do
  description "email waitlisters"
  task :waitlisters do |t|

    Waitlister.all.each do |waitlister|

      begin
      Mail.deliver do
        to waitlister.email
        from 'no-reply@hollerback.co'
        subject "hello from hollerback"

        body "./public/assets/waitlist_email_body.txt"

        end
      rescue Exception => ex
        Honeybadger.notify(ex, {:message => "couldn't send email to #{waitlister.email}"})
      end
    end


  end

end