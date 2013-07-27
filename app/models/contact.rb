class Contact < ActiveRecord::Base
  belongs_to :user

  delegate :username, to: :user

  def as_json(options={})
    options = options.merge(:only => [:username, :name, :created_at])
    super(options)
  end
end
