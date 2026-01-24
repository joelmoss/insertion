# Insertion

PORO fixtures for Rails. A simple, fast way to create test data using Plain Old Ruby Objects.

## Installation

Add to your application's Gemfile:

```ruby
gem 'insertion'
```

Then run:

```bash
bundle install
```

For convenience, include the Insertion methods in your test setup. For RSpec, add this to your `spec_helper.rb` or `test_helper.rb`:

```ruby
module ActiveSupport
  class TestCase
    include Insertion
    # ...
  end
end
```

Then you can simply call `insert` and `build` in your tests. But of course, you can also call them directly via `Insertion.insert` and `Insertion.build`.

## Usage

### Basic Usage

Create records directly in your tests:

```ruby
user = insert(:user, name: 'Joel', email: 'joel@example.com')
```

Build a record without persisting (useful for getting default values):

```ruby
user = build(:user, name: 'Joel')
```

### Custom Insert Classes

For more control, create custom Insert classes in `app/inserts/`:

```ruby
# app/inserts/user_insert.rb
class UserInsert < Insertion::Insert
  def attributes
    {
      name: 'Default Name',
      email: "user#{SecureRandom.hex(4)}@example.com",
      **super
    }
  end

  def after_insert(record)
    # Run code after the record is inserted
  end

  def after_build(record)
    # Run code after the record is built
  end
end
```

Then use it:

```ruby
# Uses defaults from UserInsert
user = insert(:user)

# Override specific attributes
user = insert(:user, name: 'Custom Name')
```

### Nested Inserts

Create associated records within your Insert classes:

```ruby
class PostInsert < Insertion::Insert
  def attributes
    {
      title: 'Default Title',
      user_id: insert(:user).id,
      **super
    }
  end
end
```

## Why Insertion?

- **Fast**: Uses `insert!` to write directly to the database, bypassing model callbacks and validations
- **Simple**: Plain Ruby classes with no DSL to learn
- **Flexible**: Override any attribute at call time

## Requirements

- Ruby >= 3.3.0
- Rails >= 7.2.0

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/joelmoss/insertion.
