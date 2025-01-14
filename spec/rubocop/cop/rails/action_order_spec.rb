# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Rails::ActionOrder, :config do
  it 'detects unconventional order of actions' do
    expect_offense(<<~RUBY)
      class UserController < ApplicationController
        def show; end
        def index; end
        ^^^^^^^^^^^^^^ Action `index` should appear before `show`.
      end
    RUBY

    expect_correction(<<~RUBY)
      class UserController < ApplicationController
        def index; end
        def show; end
      end
    RUBY
  end

  it 'supports methods with content' do
    expect_offense(<<~RUBY)
      class UserController < ApplicationController
        def show
          @user = User.find(params[:id])
        end

        def index; end
        ^^^^^^^^^^^^^^ Action `index` should appear before `show`.
      end
    RUBY

    expect_correction(<<~RUBY)
      class UserController < ApplicationController
        def index; end

        def show
          @user = User.find(params[:id])
        end
      end
    RUBY
  end

  it 'respects order of duplicate methods' do
    expect_offense(<<~RUBY)
      class UserController < ApplicationController
        def edit; end
        def index # first
        ^^^^^^^^^^^^^^^^^ Action `index` should appear before `edit`.
        end
        def show; end
        def index # second
        ^^^^^^^^^^^^^^^^^^ Action `index` should appear before `show`.
        end
      end
    RUBY

    expect_correction(<<~RUBY)
      class UserController < ApplicationController
        def index # first
        end
        def index # second
        end
        def show; end
        def edit; end
      end
    RUBY
  end

  it 'ignores non standard controller actions' do
    expect_no_offenses(<<~RUBY)
      class UserController < ApplicationController
        def index; end
        def commit; end
        def show; end
      end
    RUBY
  end

  it 'does not touch protected actions' do
    expect_no_offenses(<<~RUBY)
      class UserController < ApplicationController
        def show; end
        protected
        def index; end
      end
    RUBY
  end

  it 'does not touch inline protected actions' do
    expect_no_offenses(<<~RUBY)
      class UserController < ApplicationController
        def show; end
        protected def index; end
      end
    RUBY
  end

  it 'does not touch private actions' do
    expect_no_offenses(<<~RUBY)
      class UserController < ApplicationController
        def show; end
        private
        def index; end
      end
    RUBY
  end

  it 'does not touch inline private actions' do
    expect_no_offenses(<<~RUBY)
      class UserController < ApplicationController
        def show; end
        private def index; end
      end
    RUBY
  end

  context 'with custom ordering' do
    it 'enforces custom order' do
      cop_config['ExpectedOrder'] = %w[show index new edit create update destroy]

      expect_offense(<<~RUBY)
        class UserController < ApplicationController
          def index; end
          def show; end
          ^^^^^^^^^^^^^ Action `show` should appear before `index`.
        end
      RUBY

      expect_correction(<<~RUBY)
        class UserController < ApplicationController
          def show; end
          def index; end
        end
      RUBY
    end

    it 'does not require all actions to be specified' do
      cop_config['ExpectedOrder'] = %w[show index]

      expect_offense(<<~RUBY)
        class UserController < ApplicationController
          def index; end
          def edit; end
          def show; end
          ^^^^^^^^^^^^^ Action `show` should appear before `index`.
        end
      RUBY

      expect_correction(<<~RUBY)
        class UserController < ApplicationController
          def show; end
          def edit; end
          def index; end
        end
      RUBY
    end
  end
end
