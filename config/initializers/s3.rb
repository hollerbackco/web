require 'aws/s3'

access_key_id = ENV["AWS_ACCESS_KEY_ID"] || 'AKIAJLG6CN7ONSGY6YXA',
secret_access_key = ENV["AWS_SECRET_ACCESS_KEY"] || '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'

AWS::S3::Base.establish_connection!(
  :access_key_id     => access_key_id,
  :secret_access_key => secret_access_key
)
