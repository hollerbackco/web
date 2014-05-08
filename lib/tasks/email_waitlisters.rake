namespace :email do
  desc "email waitlisters"
  task :waitlisters do |t|

    #Waitlister.all.each do |waitlister|

      begin
        Mail.deliver do
          to 'sajjad@hollerback.co'
          from 'no-reply@hollerback.co'
          subject "hello from hollerback"

          body File.read('public/assets/waitlist_email_body.txt')

        end
      rescue Exception => ex
        p ex
        #Honeybadger.notify(ex, {:message => "couldn't send email to"})
      end
    #end


  end

end