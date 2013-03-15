sid = ENV['TWILIO_SID'] || "AC2cf0577c03154df0b1ada109823f7aaa"
secret = ENV['TWILIO_SECRET'] || "8e1955ce73520199b3bdc6305f4b6fea"
phone = ENV['TWILIO_PHONE'] || "+14155285018"

Hollerback::SMS.configure sid, secret, phone
