require 'acts_as_full_text_searchable'

ActiveRecord::Base.send :include, ActsAsFullTextSearchable
