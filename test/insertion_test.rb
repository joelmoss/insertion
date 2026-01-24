# frozen_string_literal: true

require 'test_helper'

class InsertionTest < ActiveSupport::TestCase
  it 'has a version number' do
    assert_not_nil Insertion::VERSION
  end

  describe 'Insertion.insert' do
    it 'inserts with bare model using symbol' do
      user = Insertion.insert(:user, name: 'John', email: 'john@example.com')

      assert_instance_of User, user
      assert_equal 'John', user.name
      assert_equal 'john@example.com', user.email
      assert_predicate user, :persisted?
      assert_equal 1, User.count
    end

    it 'inserts with bare model using string' do
      user = Insertion.insert('user', name: 'Jane', email: 'jane@example.com')

      assert_instance_of User, user
      assert_equal 'Jane', user.name
      assert_predicate user, :persisted?
    end

    it 'inserts with underscored model name' do
      post = Insertion.insert(:post, title: 'Hello World', body: 'Content')

      assert_instance_of Post, post
      assert_equal 'Hello World', post.title
    end

    it 'inserts with custom insert class' do
      Object.const_set(:UserInsert, Class.new(Insertion::Insert) do
        def initialize(name:, email:, age: 25)
          super(name: name.upcase, email: email, age: age)
        end
      end)

      user = Insertion.insert(:user, name: 'john', email: 'john@example.com')

      assert_equal 'JOHN', user.name
      assert_equal 25, user.age
      assert_predicate user, :persisted?
    ensure
      Object.send(:remove_const, :UserInsert)
    end

    it 'calls after_insert callback with custom insert class' do
      callback_called = false
      callback_record = nil

      Object.const_set(:UserInsert, Class.new(Insertion::Insert) do
        define_method(:after_insert) do |record|
          callback_called = true
          callback_record = record
        end
      end)

      user = Insertion.insert(:user, name: 'Test', email: 'test@example.com')

      assert callback_called
      assert_equal user.id, callback_record.id
    ensure
      Object.send(:remove_const, :UserInsert)
    end

    it 'raises argument error with class context' do
      Object.const_set(:UserInsert, Class.new(Insertion::Insert) do
        def initialize(required_arg:)
          super(name: required_arg)
        end
      end)

      error = assert_raises(Insertion::Insert::ArgumentError) do
        Insertion.insert(:user, wrong_arg: 'value')
      end
      assert_includes error.to_s, 'UserInsert'
    ensure
      Object.send(:remove_const, :UserInsert)
    end
  end

  describe 'Insertion.build' do
    before do
      User.delete_all
      Post.delete_all
    end

    it 'builds with bare model' do
      user = Insertion.build(:user, name: 'John', email: 'john@example.com')

      assert_instance_of User, user
      assert_equal 'John', user.name
      assert_not_predicate user, :persisted?
      assert_equal 0, User.count
    end

    it 'builds with custom insert class' do
      Object.const_set(:UserInsert, Class.new(Insertion::Insert) do
        def initialize(name:, email:)
          super(name: name.upcase, email: email)
        end
      end)

      user = Insertion.build(:user, name: 'john', email: 'john@example.com')

      assert_equal 'JOHN', user.name
      assert_not_predicate user, :persisted?
      assert_equal 0, User.count
    ensure
      Object.send(:remove_const, :UserInsert)
    end

    it 'calls after_build callback' do
      callback_called = false

      Object.const_set(:UserInsert, Class.new(Insertion::Insert) do
        define_method(:after_build) do |_record|
          callback_called = true
        end
      end)

      Insertion.build(:user, name: 'Test', email: 'test@example.com')

      assert callback_called
    ensure
      Object.send(:remove_const, :UserInsert)
    end

    it 'raises argument error with class context' do
      Object.const_set(:UserInsert, Class.new(Insertion::Insert) do
        def initialize(required_arg:)
          super(name: required_arg)
        end
      end)

      error = assert_raises(Insertion::Insert::ArgumentError) do
        Insertion.build(:user, wrong_arg: 'value')
      end
      assert_includes error.to_s, 'UserInsert'
    ensure
      Object.send(:remove_const, :UserInsert)
    end
  end

  describe Insertion::Insert do
    before do
      User.delete_all
      Post.delete_all
    end

    it 'class method insert delegates to Insertion' do
      Object.const_set(:PostInsert, Class.new(Insertion::Insert) do
        def initialize(title:, body: 'Default body')
          super
        end
      end)

      post = PostInsert.insert(:post, title: 'Test Title')

      assert_instance_of Post, post
      assert_equal 'Test Title', post.title
      assert_equal 'Default body', post.body
      assert_predicate post, :persisted?
    ensure
      Object.send(:remove_const, :PostInsert)
    end

    it 'has attributes accessor' do
      insert = Insertion::Insert.new(name: 'Test', email: 'test@example.com')

      assert_equal({ name: 'Test', email: 'test@example.com' }, insert.attributes)
    end

    it 'attributes defaults to empty hash' do
      insert = Insertion::Insert.new
      insert.instance_variable_set(:@attributes, nil)

      assert_empty insert.attributes
    end

    it 'has private insert helper' do
      Object.const_set(:UserInsert, Class.new(Insertion::Insert) do
        def create_with_post!
          do_insert!.tap do |user|
            insert(:post, title: 'Welcome', body: 'Hello!', user_id: user.id)
          end
        end
      end)

      user = UserInsert.new(name: 'Test', email: 'test@example.com').create_with_post!

      assert_equal 1, User.count
      assert_equal 1, Post.count
      assert_equal user.id, Post.first.user_id
    ensure
      Object.send(:remove_const, :UserInsert)
    end

    it 'has private build helper' do
      Object.const_set(:UserInsert, Class.new(Insertion::Insert) do
        def preview_with_post
          build(:post, title: 'Preview', body: 'Preview body', user_id: 1)
        end
      end)

      post = UserInsert.new(name: 'Test', email: 'test@example.com').preview_with_post

      assert_instance_of Post, post
      assert_not_predicate post, :persisted?
      assert_equal 0, Post.count
    ensure
      Object.send(:remove_const, :UserInsert)
    end
  end

  describe Insertion::Insert::Error do
    it 'formats error without class name' do
      error = Insertion::Insert::Error.new('Something went wrong')

      assert_equal 'Something went wrong', error.to_s
    end

    it 'formats error with class name' do
      error = Insertion::Insert::Error.new('Something went wrong', class_name: 'MyInsert')

      assert_equal '(MyInsert) Something went wrong', error.to_s
    end

    it 'ArgumentError inherits from Error' do
      assert_operator Insertion::Insert::ArgumentError, :<, Insertion::Insert::Error
    end
  end

  describe Insertion::BareInsert do
    before do
      User.delete_all
      Post.delete_all
    end

    it 'inserts with model class' do
      bare = Insertion::BareInsert.new(User, name: 'Test', email: 'test@example.com')
      user = bare.do_insert!

      assert_instance_of User, user
      assert_equal 'Test', user.name
      assert_predicate user, :persisted?
    end

    it 'builds with model class' do
      bare = Insertion::BareInsert.new(User, name: 'Test', email: 'test@example.com')
      user = bare.build_insert!

      assert_instance_of User, user
      assert_equal 'Test', user.name
      assert_not_predicate user, :persisted?
      assert_equal 0, User.count
    end
  end
end
