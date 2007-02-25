module ActsAsFullTextSearchable
  class Word < ::ActiveRecord::Base
    belongs_to :searchable, :polymorphic => true
  end

  def self.included(base_class)
    base_class.extend(ClassMethods)
  end
  
  module ClassMethods
    def acts_as_full_text_searchable
      class_eval do
        extend ActsAsFullTextSearchable::SingletonMethods
      end
      include ActsAsFullTextSearchable::InstanceMethods

      has_many :words, :as => :searchable, :class_name => 'ActsAsFullTextSearchable::Word'
      
      after_save :update_full_text_index
    end
  end
  
  module SingletonMethods
    def find_by_full_text_search(query)
      find_by_sql(find_by_full_text_search_sql('*', query))
    end
    
    def find_by_full_text_search_sql(columns, query)
      where_clause = full_text_query_to_sql_where_clause(query)
      columns = columns.split(' ').collect{|c| "#{table_name}.#{c}"}
       %{
        SELECT DISTINCT(#{table_name}.id), #{columns} FROM #{table_name}
        INNER JOIN #{Word.table_name} 
          ON #{Word.table_name}.searchable_type = '#{name}'
            AND #{Word.table_name}.searchable_id = #{table_name}.id
        WHERE #{where_clause}
      }
    end
    
    def full_text_query_to_sql_where_clause(query)
      query.split(' ').collect do |term|
        send(:sanitize_sql, ["#{Word.table_name}.word = ?", term.downcase])
      end.join(' AND ')
    end
  end
  
  module InstanceMethods
    def update_full_text_index
      Word.delete_all(:searchable_id => self.id, :searchable_type => self.class.name)
      full_text_indexed_attributes.each do |attribute|
        words_for(self.send(attribute)).each do |word|
          self.words.find_or_create_by_attribute_name_and_word(attribute, word)
        end
      end
    end

    private
    
    def full_text_indexed_attributes
      attributes.keys - ['id']
    end
    
    def words_for(value)
      value.to_s.split(/\s/).collect(&:downcase)
    end
  end
  
  def setup_schema
    ActiveRecord::Base.connection.create_table(Word.table_name) do |t|
      t.column 'searchable_id', :integer
      t.column 'searchable_type', :string
      t.column 'attribute_name', :string
      t.column 'word', :string
    end
  end
  module_function :setup_schema
end
