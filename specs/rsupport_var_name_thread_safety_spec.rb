require 'galaaz'

describe R::Support do
  it 'generates unique g2_v handles under concurrency' do
    n_threads = 8
    per_thread = 200
    names = []
    lock = Mutex.new

    threads = n_threads.times.map do
      Thread.new do
        local = []
        per_thread.times { local << R::Support.generate_var_name }
        lock.synchronize { names.concat(local) }
      end
    end

    threads.each(&:join)

    expect(names.length).to eq(n_threads * per_thread)
    expect(names.uniq.length).to eq(names.length)
    expect(names).to all(match(/\Ag2_v\d+\z/))
  end
end
