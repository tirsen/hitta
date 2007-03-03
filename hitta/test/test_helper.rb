require 'rubygems'
require 'test/unit'
require 'active_record'

plugin_test_dir = File.dirname(__FILE__)

ActiveRecord::Base.establish_connection({
  'adapter' => 'sqlite3',
  'database' => ':memory:'
})

load(File.join(plugin_test_dir, '..', 'init.rb'))

load(File.join(plugin_test_dir, 'schema.rb'))
ActsAsFullTextSearchable.setup_schema

require File.join(plugin_test_dir, 'post')
require File.join(plugin_test_dir, 'author')
