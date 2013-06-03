# session routes
module HollerbackApp
  class ApiApp < BaseApp
    post '/sns/et' do
      p params
      if params.key? "Message"
        jobId = params["Message"]["jobId"]
        if params["Message"]["state"] == "COMPLETED"
          StreamJob.find_by_job_id(jobId).complete!
        end
      end
    end
  end
end
