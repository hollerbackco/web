# session routes
module HollerbackApp
  class ApiApp < BaseApp
    post '/sns/et' do
      p obj = JSON.parse request.body.read
      if obj.key? "Message"
        jobId = obj["Message"]["jobId"]
        if obj["Message"]["state"] == "COMPLETED"
          StreamJob.find_by_job_id(jobId).complete!
        end
      end
    end
  end
end
