module ActsAsFullTextSearchable
  class Term < ::ActiveRecord::Base
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

      has_many :full_text_terms, :as => :searchable, :class_name => 'ActsAsFullTextSearchable::Term'
      
      after_save :update_full_text_index
    end
  end
  
  module SingletonMethods
    def find_by_full_text_search(query)
      find_by_sql(find_by_full_text_search_sql('*', query))
    end
    
    def find_by_full_text_search_sql(columns, query)
      where_clause = full_text_query_to_sql_where_clause(query)
      "SELECT DISTINCT(id), #{columns} FROM #{table_name} WHERE #{where_clause}"
    end
    
    def single_term_full_text_query_to_sql(query_term)
      send(:sanitize_sql, [%{
        SELECT DISTINCT(#{table_name}.id) FROM #{table_name}
        INNER JOIN #{Term.table_name} 
          ON #{Term.table_name}.searchable_type = '#{name}'
            AND #{Term.table_name}.searchable_id = #{table_name}.id
        WHERE LOWER(#{Term.table_name}.term) = LOWER(?)
      }, query_term])
    end
    
    def full_text_query_to_sql_where_clause(query)
      query.split(' ').collect do |term|
        "id IN (#{single_term_full_text_query_to_sql(term)})"
      end.join(' AND ')
    end
  end
  
  module InstanceMethods
    def update_full_text_index
      Term.delete_all(:searchable_id => self.id, :searchable_type => self.class.name)
      full_text_indexed_attributes.each do |attribute|
        full_text_terms_for(self.send(attribute)).each do |term|
          self.full_text_terms.find_or_create_by_attribute_name_and_term(attribute, term)
        end
      end
    end

    private
    
    def full_text_indexed_attributes
      attributes.keys - ['id']
    end
    
    def full_text_terms_for(value)
      value.to_s.split(/\s/).collect(&:downcase)
    end
  end
  
  def setup_schema
    ActiveRecord::Base.connection.create_table(Term.table_name) do |t|
      t.column 'searchable_id', :integer
      t.column 'searchable_type', :string
      t.column 'attribute_name', :string
      t.column 'term', :string
    end
  end
  module_function :setup_schema
end
