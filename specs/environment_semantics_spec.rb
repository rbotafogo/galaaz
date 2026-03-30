# frozen_string_literal: true

require 'galaaz'

describe R::Environment do
  def new_env
    R::Support.eval('new.env(parent = emptyenv())')
  end

  context 'creation and key/value operations' do
    it 'creates an environment handle from new.env()' do
      env = new_env
      expect(env).to be_a(R::Environment)
      expect(env.typeof).to eq R.c('environment')
      expect(env.rclass).to eq R.c('environment')
    end

    it 'supports set/get and dot assignment accessors' do
      env = new_env

      env.set(:a, 25)
      expect(env.get(:a)).to eq 25

      env.b = 33
      expect(env.b).to eq 33

      env.vec = R.c(1, 2, 3, 4)
      expect(env.vec).to eq R.c(1, 2, 3, 4)
      expect(R.ls(envir: env).all__equal(R.c('a', 'b', 'vec'))).to eq true
    end
  end

  context 'remove and invalid subsetting semantics' do
    it 'removes an environment binding with rm()' do
      env = new_env
      env.a = false
      env.b = 'x'
      expect(env.a).to eq false

      R.rm('a', envir: env)
      expect { env.a }.to raise_error(NoMethodError)
      expect(R.ls(envir: env).all__equal(R.c('b'))).to eq true
    end

    it "raises bridge process error when using [] on environment" do
      env = new_env
      env.a = 1
      expect { env['a'] }.to raise_error(NewBridge::SessionClient::RProcessError)
    end
  end
end
