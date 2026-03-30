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

  it 'captures snapshots across plot pages and saves both artifacts' do
    work = Dir.mktmpdir('plot_snapshot_multi_')

    begin
      Dir.chdir(work) do
        dev = R::Device.new('png', width: 4, height: 3, dpi: 96, record: true)
        dev.open

        R.barplot(R.c(2, 5, 3, 4))
        snap1 = dev.plot_snapshot
        out1 = dev.save_plot(snap1, 'snapshot_page1', 'png', 4, 3, 'png', 96)

        R::Support.eval('grid::grid.newpage(recording = TRUE)')
        R.plot(R.c(1, 2, 3, 4))
        snap2 = dev.plot_snapshot
        out2 = dev.save_plot(snap2, 'snapshot_page2', 'png', 4, 3, 'png', 96)

        dev.close

        path1 = File.join(work, out1.to_s)
        path2 = File.join(work, out2.to_s)
        expect(File.exist?(path1)).to eq(true)
        expect(File.size(path1)).to be > 0
        expect(File.exist?(path2)).to eq(true)
        expect(File.size(path2)).to be > 0
      end
    ensure
      FileUtils.rm_rf(work) if work && File.directory?(work)
    end
  end
end
