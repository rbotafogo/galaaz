# frozen_string_literal: true

require 'galaaz'
require 'tmpdir'

describe 'Plot snapshot/save semantics' do
  it 'captures and saves recorded plot via R::Device helpers in plain runtime' do
    work = Dir.mktmpdir('plot_snapshot_')

    begin
      Dir.chdir(work) do
        dev = R::Device.new('png', width: 4, height: 3, dpi: 96, record: true)
        dev.open
        R.barplot(R.c(3, 1, 4, 2))
        snap = dev.plot_snapshot
        out_file = dev.save_plot(snap, 'snapshot_test', 'png', 4, 3, 'png', 96)
        dev.close

        path = File.join(work, out_file.to_s)
        expect(File.exist?(path)).to eq(true)
        expect(File.size(path)).to be > 0
      end
    ensure
      FileUtils.rm_rf(work) if work && File.directory?(work)
    end
  end
end
