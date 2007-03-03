load File.join(File.dirname(__FILE__), 'test_helper.rb')

class ActsAsFullTextSearchableTest < Test::Unit::TestCase
  def setup
    Post.destroy_all
    @jon = Author.create!(:name => 'Jon Tirsen')
    @post = Post.create!(:title => 'Ruby number 1 programming language', :body => 'Blah blah blah', :author => @jon)
  end
  
  def test_can_create_term_index
    assert_equal ["1", "blah", "language", "number", "programming", "ruby"], 
      ActsAsFullTextSearchable::Term.find(:all).collect(&:term).sort
  end
  
  def test_can_do_full_text_search
    assert_equal 1, Post.find(:all, :full_text_search => 'blah').size
    assert_equal @post, Post.find(:all, :full_text_search => 'blah').first
  end
  
  def test_updates_index_when_object_is_updated
    @post.title = 'Something entirely different'
    @post.body = 'Yadda yadda yadda'
    @post.save!
    assert_equal 0, Post.find(:all, :full_text_search => 'blah').size
    assert_equal @post, Post.find(:all, :full_text_search => 'yadda').first
  end
  
  def test_is_case_insensitive
    assert_equal 1, Post.find(:all, :full_text_search => 'blah').size
    assert_equal 1, Post.find(:all, :full_text_search => 'Blah').size
    assert_equal 1, Post.find(:all, :full_text_search => 'BlaH').size
  end
  
  def test_can_search_for_multiple_terms
    assert_equal @post, Post.find(:all, :full_text_search => 'blah ruby').first
    assert_equal 0, Post.find(:all, :full_text_search => 'yadda ruby').size
    assert_equal 1, Post.find(:all, :full_text_search => 'blah blah').size
  end
end