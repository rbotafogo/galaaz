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

    it 'supports env_names from environment object and R helper (legacy Galaaz)' do
      env = new_env
      expect(env.env_names.length).to eq 0
      expect(R.env_names(env).length).to eq 0

      env.a = 30
      env.vec = R.c(1, 2, 3, 4)
      expect(env.env_names.length).to eq 2
      expect(R.env_names(env).all__equal(R.c('a', 'vec'))).to eq true
    end

    it 'supports element lookup with [[]] by name' do
      env = new_env
      env.a = 'This is a string'
      expect(env[['a']]).to eq R.c('This is a string')
    end

    it 'allows multiple names to reference the same assigned object' do
      env = new_env
      env.d = R.c(1, 2, 3)
      env.a = env.d
      expect(env.a).to eq R.c(1, 2, 3)
      expect(env.d).to eq R.c(1, 2, 3)
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

  context 'expression evaluation in environment context' do
    it 'evaluates expression against environment bindings when parent has base operators' do
      env = R::Support.eval('new.env(parent = baseenv())')
      env.e1 = 10
      env.e2 = 20
      env.e3 = R.c(1, 2, 3, 4)

      expr = R[:e1] + R[:e2] + R[:e3]
      expect(expr.to_s).to eq('e1 + e2 + e3')
      expect(expr.eval(env)).to eq R.c(31, 32, 33, 34)
    end
  end
end
