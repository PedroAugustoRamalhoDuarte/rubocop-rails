# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Rails::Presence, :config do
  shared_examples 'offense' do |source, correction, first_line, end_line|
    it 'registers an offense' do
      offenses = inspect_source(source)

      expect(offenses.count).to eq 1
      expect(offenses).to all(have_attributes(first_line: first_line, last_line: end_line))
      expect(offenses).to all(have_attributes(message: "Use `#{correction}` instead of `#{source}`."))
    end

    it 'auto correct' do
      expect(autocorrect_source(source)).to eq(correction)
    end
  end

  it_behaves_like 'offense', 'a.present? ? a : nil', 'a.presence', 1, 1
  it_behaves_like 'offense', '!a.present? ? nil: a', 'a.presence', 1, 1
  it_behaves_like 'offense', 'a.blank? ? nil : a', 'a.presence', 1, 1
  it_behaves_like 'offense', '!a.blank? ? a : nil', 'a.presence', 1, 1
  it_behaves_like 'offense', 'a.present? ? a : b', 'a.presence || b', 1, 1
  it_behaves_like 'offense', '!a.present? ? b : a', 'a.presence || b', 1, 1
  it_behaves_like 'offense', 'a.blank? ? b : a', 'a.presence || b', 1, 1
  it_behaves_like 'offense', '!a.blank? ? a : b', 'a.presence || b', 1, 1
  it_behaves_like 'offense', 'a.present? ? a : 1', 'a.presence || 1', 1, 1
  it_behaves_like 'offense', 'a.blank? ? 1 : a', 'a.presence || 1', 1, 1

  it_behaves_like 'offense',
                  'a(:bar).map(&:baz).present? ? a(:bar).map(&:baz) : nil',
                  'a(:bar).map(&:baz).presence',
                  1, 1

  it_behaves_like 'offense', 'a.present? ? a : b[:c]', 'a.presence || b[:c]', 1, 1

  it_behaves_like 'offense', <<~RUBY.chomp, 'a.presence', 1, 5
    if a.present?
      a
    else
      nil
    end
  RUBY

  it_behaves_like 'offense', <<~RUBY.chomp, 'a.presence', 1, 5
    unless a.present?
      nil
    else
      a
    end
  RUBY

  it_behaves_like 'offense', <<~RUBY.chomp, 'a.presence || b.to_f + 12.0', 1, 5
    if a.present?
      a
    else
      b.to_f + 12.0
    end
  RUBY

  it_behaves_like 'offense', <<~RUBY.chomp, 'a.presence || b.to_f * 12.0', 1, 5
    if a.present?
      a
    else
      b.to_f * 12.0
    end
  RUBY

  it_behaves_like 'offense', 'a if a.present?', 'a.presence', 1, 1
  it_behaves_like 'offense', 'a unless a.blank?', 'a.presence', 1, 1
  it_behaves_like 'offense', <<~RUBY.chomp, <<~FIXED.chomp, 1, 7
    if [1, 2, 3].map { |num| num + 1 }
                .map { |num| num + 2 }
                .present?
      [1, 2, 3].map { |num| num + 1 }.map { |num| num + 2 }
    else
      b
    end
  RUBY
    [1, 2, 3].map { |num| num + 1 }
                .map { |num| num + 2 }.presence || b
  FIXED

  context 'when a method argument of `else` branch is enclosed in parentheses' do
    it_behaves_like 'offense', <<~SOURCE.chomp, <<~CORRECTION.chomp, 1, 5
      if value.present?
        value
      else
        do_something(value)
      end
    SOURCE
      value.presence || do_something(value)
    CORRECTION
  end

  context 'when a method argument of `else` branch is not enclosed in parentheses' do
    it_behaves_like 'offense', <<~SOURCE.chomp, <<~CORRECTION.chomp, 1, 5
      if value.present?
        value
      else
        do_something value
      end
    SOURCE
      value.presence || do_something(value)
    CORRECTION
  end

  context 'when multiple method arguments of `else` branch is not enclosed in parentheses' do
    it_behaves_like 'offense', <<~SOURCE.chomp, <<~CORRECTION.chomp, 1, 5
      if value.present?
        value
      else
        do_something arg1, arg2
      end
    SOURCE
      value.presence || do_something(arg1, arg2)
    CORRECTION
  end

  context 'when a method argument with a receiver of `else` branch is not enclosed in parentheses' do
    it_behaves_like 'offense', <<~SOURCE.chomp, <<~CORRECTION.chomp, 1, 5
      if value.present?
        value
      else
        foo.do_something value
      end
    SOURCE
      value.presence || foo.do_something(value)
    CORRECTION
  end

  it 'does not register an offense when using `#presence`' do
    expect_no_offenses(<<~RUBY)
      a.presence
    RUBY
  end

  it 'does not register an offense when the expression does not return the receiver of `#present?`' do
    expect_no_offenses(<<~RUBY)
      a.present? ? b : nil
    RUBY

    expect_no_offenses(<<~RUBY)
      puts foo if present?
      puts foo if !present?
    RUBY
  end

  it 'does not register an offense when the expression does not return the receiver of `#blank?`' do
    expect_no_offenses(<<~RUBY)
      a.blank? ? nil : b
    RUBY

    expect_no_offenses(<<~RUBY)
      puts foo if blank?
      puts foo if !blank?
    RUBY
  end

  it 'does not register an offense when if or unless modifier is used' do
    [
      'a if a.blank?',
      'a unless a.present?'
    ].each { |source| expect_no_offenses(source) }
  end

  it 'does not register an offense when the else block is multiline' do
    expect_no_offenses(<<~RUBY)
      if a.present?
        a
      else
        something
        something
        something
      end
    RUBY
  end

  it 'does not register an offense when the else block has multiple statements' do
    expect_no_offenses(<<~RUBY)
      if a.present?
        a
      else
        something; something; something
      end
    RUBY
  end

  it 'does not register an offense when including the elsif block' do
    expect_no_offenses(<<~RUBY)
      if a.present?
        a
      elsif b
        b
      end
    RUBY
  end

  it 'does not register an offense when the else block has `if` node' do
    expect_no_offenses(<<~RUBY)
      if a.present?
        a
      else
        b if c
      end
    RUBY
  end

  it 'does not register an offense when the else block has `rescue` node' do
    expect_no_offenses(<<~RUBY)
      if something_method.present?
        something_method
      else
        invalid_method rescue StandardError
      end
    RUBY
  end

  it 'does not register an offense when the else block has `while` node' do
    expect_no_offenses(<<~RUBY)
      if a.present?
        a
      else
        fetch_state while waiting?
      end
    RUBY
  end

  it 'does not register an offense when using #present? with elsif block' do
    expect_no_offenses(<<~RUBY)
      if something?
        a
      elsif b.present?
        b
      end
    RUBY
  end
end
