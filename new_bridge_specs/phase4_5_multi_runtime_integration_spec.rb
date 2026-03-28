# frozen_string_literal: true

# Phase 4.5: real multi-runtime integration (local + 2 dockerized R versions).
# Run: bundle exec rspec specs/new_bridge/phase4_5_multi_runtime_integration_spec.rb

require 'open3'
require 'tmpdir'

root = File.expand_path('../..', __dir__)
$LOAD_PATH.unshift(File.join(root, 'lib')) unless $LOAD_PATH.include?(File.join(root, 'lib'))

require 'new_bridge'

RSpec.describe 'NewBridge Phase 4.5 (local + container multi-version)' do
  let(:phase1_cpp) { File.expand_path('../ext/new_bridge/galaaz_gatekeeper_phase1.cpp', __dir__) }

  def project_root
    File.expand_path('../..', __dir__)
  end

  def docker_ok?
    system("docker info >/dev/null 2>&1")
  end

  def image_exists?(tag)
    system("docker image inspect #{tag} >/dev/null 2>&1")
  end

  def ensure_r_bridge_image!(tag:, base_image:)
    if image_exists?(tag)
      puts "[phase4.5] image already available: #{tag}"
      return
    end

    puts "[phase4.5] building image #{tag} from #{base_image} (this can take a while)..."

    dockerfile = <<~DOCKERFILE
      FROM #{base_image}
      RUN R -q -e "install.packages('Rcpp', repos='https://cloud.r-project.org/')"
    DOCKERFILE

    out, err, st = Open3.capture3(
      'docker', 'build', '-t', tag, '-f', '-', '.',
      stdin_data: dockerfile,
      chdir: project_root
    )
    return if st.success?

    raise "failed to build #{tag} from #{base_image}\nSTDOUT:\n#{out}\nSTDERR:\n#{err}"
  end

  def r_minor_code_expr
    # Encode R major/minor into a single integer.
    # Example: 4.3.x -> 403, 3.6.x -> 306
    "as.integer(R.version$major) * 100L + as.integer(strsplit(R.version$minor, '\\\\.')[[1]][1])"
  end

  before(:all) do
    skip 'R not on PATH' unless system('command -v R >/dev/null 2>&1')
    skip 'docker not available' unless system('docker info >/dev/null 2>&1')
  end

  it 'executes same calculation on local + latest container + 3.x container' do
    puts '[phase4.5] starting multi-runtime integration'
    latest_tag = 'galaaz/r-bridge:4.3.3'
    legacy_tag = 'galaaz/r-bridge:3.6.3'

    ensure_r_bridge_image!(tag: latest_tag, base_image: 'rocker/r-ver:4.3.3')
    ensure_r_bridge_image!(tag: legacy_tag, base_image: 'rocker/r-ver:3.6.3')

    mgr = NewBridge::RInstanceManager.new(source_path: phase1_cpp)

    puts '[phase4.5] spawning local runtime'
    mgr.spawn(runtime: 'local', instance_id: 'local-r', version: 'local')
    puts '[phase4.5] spawning container runtime 4.3.3'
    mgr.spawn(runtime: 'container', instance_id: 'ctr-latest', version: '4.3.3', image: latest_tag, accept_timeout: 35)
    puts '[phase4.5] spawning container runtime 3.6.3'
    mgr.spawn(runtime: 'container', instance_id: 'ctr-legacy', version: '3.6.3', image: legacy_tag, accept_timeout: 35)

    # Same expression through all runtimes.
    expr = '40L + 2L'
    local_out = mgr.eval_with_version(expr, version: 'local', session_id: 'same-expr')
    v43_out = mgr.eval_with_version(expr, version: '4.3.3', session_id: 'same-expr')
    v36_out = mgr.eval_with_version(expr, version: '3.6.3', session_id: 'same-expr')

    expect(local_out['value']).to eq(42)
    expect(v43_out['value']).to eq(42)
    expect(v36_out['value']).to eq(42)

    # Verify version families are really different between containers.
    v_local = mgr.eval_with_version(r_minor_code_expr, version: 'local', session_id: 'ver')
    v_latest = mgr.eval_with_version(r_minor_code_expr, version: '4.3.3', session_id: 'ver')
    v_legacy = mgr.eval_with_version(r_minor_code_expr, version: '3.6.3', session_id: 'ver')

    expect(v_latest['value']).to be >= 403
    expect(v_legacy['value']).to be_between(300, 399).inclusive
    expect(v_latest['value']).not_to eq(v_legacy['value'])
    expect(v_local['value']).to be >= 300
  ensure
    puts '[phase4.5] stopping non-default runtimes and forcing container cleanup'
    mgr&.set_default_instance('local-r')
    mgr&.stop_all(keep_default: true, force_container: true)
    puts '[phase4.5] stopping default local runtime'
    mgr&.stop_all(force_container: true)
  end
end

