# frozen_string_literal: true

root = File.expand_path('../..', __dir__)
$LOAD_PATH.unshift(File.join(root, 'lib')) unless $LOAD_PATH.include?(File.join(root, 'lib'))

require 'stringio'
require 'new_bridge/bootstrap/windows_bootstrap'

RSpec.describe NewBridge::Bootstrap::WindowsBootstrap do
  def runner_for(map, calls)
    lambda do |cmd|
      calls << cmd
      data = map.fetch(cmd, [false, '', 'not mocked', 127])
      data
    end
  end

  it 'reports ready in check mode when docker requirements pass' do
    calls = []
    map = {
      'command -v docker' => [true, '/usr/bin/docker', '', 0],
      "docker info --format '{{.ServerVersion}}'" => [true, '27.0.0', '', 0],
      'docker compose version' => [true, 'Docker Compose version v2.29.0', '', 0],
      'command -v ruby' => [true, '/usr/bin/ruby', '', 0],
      'command -v R' => [true, '/usr/bin/R', '', 0],
      %q{Rscript -e "quit(status = ifelse(requireNamespace('Rcpp', quietly=TRUE), 0, 1))"} => [true, '', '', 0],
      'R --version | head -n 1' => [true, 'R version 4.3.3', '', 0]
    }

    out = StringIO.new
    b = described_class.new(out: out, command_runner: runner_for(map, calls), wsl_override: true)
    result = b.run(mode: :check, runtime_mode: :docker)

    expect(result[:ready]).to be(true)
    expect(result[:exit_code]).to eq(0)
    expect(result[:checks].all? { |c| c[:ok] }).to be(true)
  end

  it 'reports not ready in docker mode when docker is missing' do
    calls = []
    map = {
      'command -v docker' => [false, '', '', 127],
      "docker info --format '{{.ServerVersion}}'" => [false, '', '', 1],
      'docker compose version' => [false, '', '', 1],
      'command -v ruby' => [true, '/usr/bin/ruby', '', 0],
      'command -v R' => [true, '/usr/bin/R', '', 0],
      %q{Rscript -e "quit(status = ifelse(requireNamespace('Rcpp', quietly=TRUE), 0, 1))"} => [true, '', '', 0],
      'R --version | head -n 1' => [true, 'R version 4.3.3', '', 0]
    }

    out = StringIO.new
    b = described_class.new(out: out, command_runner: runner_for(map, calls), wsl_override: true)
    result = b.run(mode: :check, runtime_mode: :docker)

    expect(result[:ready]).to be(false)
    expect(result[:exit_code]).to eq(1)
    docker_check = result[:checks].find { |c| c[:name] == 'docker_cli' }
    expect(docker_check[:ok]).to be(false)
  end

  it 'attempts WSL docker install in apply mode when docker CLI is missing' do
    calls = []
    map = {
      # initial checks
      'command -v docker' => [false, '', '', 127],
      "docker info --format '{{.ServerVersion}}'" => [false, '', '', 1],
      'docker compose version' => [false, '', '', 1],
      'command -v ruby' => [true, '/usr/bin/ruby', '', 0],
      'command -v R' => [true, '/usr/bin/R', '', 0],
      %q{Rscript -e "quit(status = ifelse(requireNamespace('Rcpp', quietly=TRUE), 0, 1))"} => [true, '', '', 0],
      'R --version | head -n 1' => [true, 'R version 4.3.3', '', 0],

      # apply actions
      'sudo apt-get update' => [true, '', '', 0],
      'sudo apt-get install -y docker.io' => [true, '', '', 0],
      'sudo apt-get install -y docker-compose-plugin' => [true, '', '', 0],
      'sudo usermod -aG docker testuser' => [true, '', '', 0],
      'sudo service docker start || sudo systemctl start docker' => [true, '', '', 0]
    }

    env = { 'USER' => 'testuser' }
    out = StringIO.new
    b = described_class.new(out: out, command_runner: runner_for(map, calls), env: env, wsl_override: true)
    result = b.run(mode: :apply, runtime_mode: :docker)

    expect(result[:actions]).to include('install_docker_wsl')
    expect(calls).to include('sudo apt-get update')
    expect(calls).to include('sudo apt-get install -y docker.io')
    expect(calls).to include('sudo apt-get install -y docker-compose-plugin')
    expect(calls).to include('sudo usermod -aG docker testuser')
  end

  it 'is ready in local mode when R and Rcpp are present even if docker is missing' do
    calls = []
    map = {
      'command -v docker' => [false, '', '', 127],
      "docker info --format '{{.ServerVersion}}'" => [false, '', '', 1],
      'docker compose version' => [false, '', '', 1],
      'command -v ruby' => [true, '/usr/bin/ruby', '', 0],
      'command -v R' => [true, '/usr/bin/R', '', 0],
      %q{Rscript -e "quit(status = ifelse(requireNamespace('Rcpp', quietly=TRUE), 0, 1))"} => [true, '', '', 0],
      'R --version | head -n 1' => [true, 'R version 4.3.3', '', 0]
    }

    out = StringIO.new
    b = described_class.new(out: out, command_runner: runner_for(map, calls), wsl_override: true)
    result = b.run(mode: :check, runtime_mode: :local)

    expect(result[:ready]).to be(true)
    expect(result[:exit_code]).to eq(0)
    expect(result[:runtime_mode]).to eq(:local)
    expect(out.string).to include('Local runtime available: R version 4.3.3')
  end

  it 'auto mode prefers local when R and Rcpp are available' do
    calls = []
    map = {
      'command -v docker' => [true, '/usr/bin/docker', '', 0],
      "docker info --format '{{.ServerVersion}}'" => [false, '', 'permission denied', 1],
      'docker compose version' => [true, 'Docker Compose version v2.29.0', '', 0],
      'command -v ruby' => [true, '/usr/bin/ruby', '', 0],
      'command -v R' => [true, '/usr/bin/R', '', 0],
      %q{Rscript -e "quit(status = ifelse(requireNamespace('Rcpp', quietly=TRUE), 0, 1))"} => [true, '', '', 0],
      'R --version | head -n 1' => [true, 'R version 4.3.3', '', 0]
    }

    out = StringIO.new
    b = described_class.new(out: out, command_runner: runner_for(map, calls), wsl_override: true)
    result = b.run(mode: :check, runtime_mode: :auto)

    expect(result[:runtime_mode]).to eq(:local)
    expect(result[:ready]).to be(true)
    expect(result[:exit_code]).to eq(0)
    expect(out.string).to include('Auto runtime selection: local')
  end
end

