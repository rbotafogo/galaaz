# frozen_string_literal: true

# Fast R::Job coverage (child Rscript; bridge stays free).
# Run: bin/run_rspec specs/r_job_spec.rb

require 'fileutils'
require 'tmpdir'
require 'galaaz'

describe 'R::Job' do
  around do |example|
    Dir.mktmpdir('galaaz_jobs_') do |jobs|
      old = ENV['GALAAZ_JOBS_DIR']
      ENV['GALAAZ_JOBS_DIR'] = jobs
      begin
        example.run
      ensure
        ENV['GALAAZ_JOBS_DIR'] = old
      end
    end
  end

  it 'awaits eval in a block and load_rds on the bridge' do
    coef = R::Job.eval(<<~R) { |job| job.load_rds }
      fit <- lm(mpg ~ wt, data = mtcars)
      saveRDS(unname(coef(fit)), result_path)
    R

    expect(coef).to be_a(R::Vector)
    expect(coef.length).to eq(2)
  end

  it 'returns a Job without a block and supports wait: false' do
    job = R::Job.eval('Sys.sleep(0.2); saveRDS(42L, result_path)', wait: false, timeout: 30)
    expect(job).to be_a(R::Job)
    expect(job.alive? || !job.finished?).to eq(true)

    job.wait(timeout: 30)
    job.raise_if_failed!
    expect(job.status).to eq(:ok)
    expect(job.load_rds.to_s).to include('42')
  end

  it 'kills the child process group on await timeout' do
    expect {
      R::Job.eval('Sys.sleep(30)', wait: true, timeout: 1)
    }.to raise_error(R::Job::Timeout, /still running after/)
  end

  it 'runs a script with trailing args and load_rds' do
    Dir.mktmpdir('galaaz_job_script_') do |dir|
      path = File.join(dir, 'train.R')
      File.write(path, <<~R)
        args <- commandArgs(trailingOnly = TRUE)
        n <- as.integer(args[[1]])
        saveRDS(n, result_path)
      R

      n = R::Job.script(path, '7') { |job| job.load_rds }
      expect(n.to_s).to include('7')
    end
  end

  it 'clears a stale 00LOCK before install' do
    Dir.mktmpdir('galaaz_job_lib_') do |lib|
      lock = File.join(lib, '00LOCK-definitely_not_a_cran_pkg_xyzzy')
      FileUtils.mkdir_p(lock)
      File.write(File.join(lock, 'marker'), 'stale')

      job = R::Job.install(
        'definitely_not_a_cran_pkg_xyzzy',
        lib_dir: lib,
        wait: true,
        timeout: 120
      )

      expect(File.exist?(lock)).to eq(false)
      expect(job.status).to eq(:failed)
    end
  end
end
