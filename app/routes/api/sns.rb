# session routes
module HollerbackApp
  class ApiApp < BaseApp
    post '/sns/et' do
      obj = JSON.parse request.body.read
      p obj 
      if obj.key? "Message"
        jobId = obj["Message"]["jobId"]
        if obj["Message"]["state"] == "COMPLETED"
          StreamJob.find_by_job_id(jobId).complete!
        end
      end
    end
  end
end
