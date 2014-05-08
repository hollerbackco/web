namespace :email do
  desc "email waitlisters"
  task :waitlisters do |t|

    Waitlister.all.each do |waitlister|
      begin
        p "#{waitlister.email}"
        Mail.deliver do
          to waitlister.email
          from 'no-reply@hollerback.co'
          subject "hello from hollerback"

          body File.read('public/assets/waitlist_email_body.txt')

        end
      rescue Exception => ex
        Honeybadger.notify(ex, {:message => "couldn't send email to #{waitlister.email}"})
      end
    end


  end

end