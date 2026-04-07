# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require 'galaaz'

describe GalaazUtil do
  describe '.inline_file_path' do
    it 'resolves a local .rb file when relative is true' do
      Dir.mktmpdir('galaaz_inline_local') do |dir|
        file = File.join(dir, 'snippet.rb')
        File.write(file, "puts 'ok'\n")

        path = GalaazUtil.inline_file_path('snippet', true, dir)
        expect(path).to eq(file)
      end
    end

    it 'resolves from load path when relative is false' do
      Dir.mktmpdir('galaaz_inline_loadpath') do |dir|
        file = File.join(dir, 'from_load_path.rb')
        File.write(file, "puts 'loadpath'\n")

        begin
          $LOAD_PATH.unshift(dir)
          path = GalaazUtil.inline_file_path('from_load_path', false, '/tmp')
          expect(path).to eq(file)
        ensure
          $LOAD_PATH.delete(dir)
        end
      end
    end

    it 'raises when file cannot be found' do
      expect do
        GalaazUtil.inline_file_path('definitely_missing_file_abc_xyz', false, '/tmp')
      end.to raise_error(Errno::ENOENT)
    end
  end

  describe '.inline_file' do
    it 'returns full file contents' do
      Dir.mktmpdir('galaaz_inline_read') do |dir|
        file = File.join(dir, 'content.rb')
        body = "a = 1\nb = 2\nputs a + b\n"
        File.write(file, body)

        code = GalaazUtil.inline_file('content', true, dir)
        expect(code).to eq(body)
      end
    end
  end
end

