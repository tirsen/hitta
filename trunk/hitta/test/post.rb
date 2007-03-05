class Post < ActiveRecord::Base
  belongs_to :author
  
  acts_as_full_text_searchable
end
