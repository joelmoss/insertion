# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Insertion is a Ruby gem / Rails engine that provides PORO (Plain Old Ruby Object) fixtures for test data creation. It uses direct database `insert!` to bypass model callbacks and validations for fast test data setup.

## Common Commands

### Install dependencies
```
bundle install
```

### Run tests (all Rails versions via Appraisal)
```
bundle exec appraisal rails test
```

### Run tests for a specific Rails version
```
bundle exec appraisal rails-7-2 rails test
bundle exec appraisal rails-8-0 rails test
```

### Run a single test file
```
bundle exec ruby -Itest test/insertion_test.rb
```

### Run a single test by line number (via maxitest)
```
bundle exec ruby -Itest test/insertion_test.rb:LINE_NUMBER
```

### Lint
```
bundle exec rubocop -P --fail-level C
```

### Regenerate Appraisal gemfiles
```
bundle exec appraisal generate
```

## Architecture

The gem has three core classes:

- **`Insertion` module** (`lib/insertion.rb`) — Public API with two entry points: `Insertion.insert(:model, **attrs)` and `Insertion.build(:model, **attrs)`. Looks up a custom Insert class (e.g., `UserInsert` for `:user`) or falls back to `BareInsert`.

- **`Insertion::Insert`** (`lib/insertion/insert.rb`) — Base class for custom insert classes. Provides `do_insert!` (persists) and `build_insert!` (transactional rollback). Supports `after_insert`/`after_build` callbacks and private `insert()`/`build()` helpers for nested associated records.

- **`Insertion::BareInsert`** (`lib/insertion/bare_insert.rb`) — Minimal wrapper used when no custom Insert class exists for a model.

The Rails integration is via `Insertion::Railtie` in `lib/insertion/engine.rb`.

## Testing

Tests use **Minitest** with **maxitest** (for line-number test selection) and **minitest-spec-rails** (for spec-style `describe`/`it` blocks). The test suite lives in `test/insertion_test.rb` with a dummy Rails app in `test/dummy/` (SQLite, two models: `User` has_many `Post`).

CI tests against Ruby 3.3, 3.4, and 4.0 with Rails 7.2 and 8.0 via Appraisals.

## Code Style

- Max line length: 100 characters
- `unless`, `and`/`or`/`not`, and numbered block parameters are disabled via rubocop
- Indented internal methods style
- Target Ruby version: 3.3+, Rails: 7.2+

## Conventions

- Custom Insert classes are named `{ModelName}Insert` (e.g., `UserInsert`)
- Users place Insert classes in `app/inserts/` in their Rails app
- The model class is derived from the Insert class name automatically
