class MessageGroup < ActiveRecord::Base
  belongs_to :membership
  has_many   :messages

  serialize :group_info, ActiveRecord::Coders::Hstore
end