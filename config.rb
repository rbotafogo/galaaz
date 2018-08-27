require 'rbconfig'

#
# In principle should not be in this file.  The right way of doing this is by executing
# bundler exec, but I don't know how to do this from inside emacs.  So, should comment
# the next line before publishing the GEM.  If not commented, this should be harmless
# anyway.
#

begin
  require 'bundler/setup'
rescue LoadError
end

$CONFIG = true

##########################################################################################
# Configuration. Remove setting before publishing Gem.
##########################################################################################

# set to true if development environment
$DVLP = true

# Set development dependency: those are gems that are also in development and thus not
# installed in the gem directory.  Need a way of accessing them if we are in development
# otherwise gem install will install the dependency
if $DVLP
  $DEPEND=["cantata"]
end

##########################################################################################

#---------------------------------------------------------------------------------------
# Add path to load path
#---------------------------------------------------------------------------------------

def mklib(path, home_path = true)
  
  if (home_path)
    lib = path + "/lib"
  else
    lib = path
  end
  
  $LOAD_PATH << lib
  
end

  
#---------------------------------------------------------------------------------------
# Return the given path.  When not in cygwin then just use the given path
#---------------------------------------------------------------------------------------

def set_path(path)
  path
end
  
#---------------------------------------------------------------------------------------
# Set the project directories
#---------------------------------------------------------------------------------------

class Cantata

  @home_dir = File.expand_path File.dirname(__FILE__)

  class << self
    attr_reader :home_dir
  end

  @project_dir = Cantata.home_dir + "/.."
  @doc_dir = Cantata.home_dir + "/doc"
  @lib_dir = Cantata.home_dir + "/lib"
  @src_dir = Cantata.home_dir + "/src"
  @target_dir = Cantata.home_dir + "/target"
  @test_dir = Cantata.home_dir + "/test"
  @vendor_dir = Cantata.home_dir + "/vendor"
  @r_dir = Cantata.home_dir + "/R"
  
  class << self
    attr_reader :project_dir
    attr_reader :doc_dir
    attr_reader :lib_dir
    attr_reader :src_dir
    attr_reader :target_dir
    attr_reader :test_dir
    attr_reader :vendor_dir
    attr_reader :cran_dir
  end

  @build_dir = Cantata.src_dir + "/build"

  class << self
    attr_accessor :build_dir
  end

  @classes_dir = Cantata.build_dir + "/classes"

  class << self
    attr_reader :classes_dir
  end

end


#---------------------------------------------------------------------------------------
# Set dependencies
#---------------------------------------------------------------------------------------

def depend(name)
  
  dependency_dir = Cantata.project_dir + "/" + name
  mklib(dependency_dir)
  
end

##########################################################################################
# If development
##########################################################################################

if ($DVLP == true)

  mklib(Cantata.home_dir)
  
  # Add dependencies here
  # depend(<other_gems>)
  $DEPEND.each do |dep|
    depend(dep)
  end if $DEPEND

  #----------------------------------------------------------------------------------------
  # If we need to test for coverage
  #----------------------------------------------------------------------------------------
  
  if $COVERAGE == 'true'
  
    require 'simplecov'
    
    SimpleCov.start do
      @filters = []
      add_group "Cantata", "lib"
    end
    
  end

end

##########################################################################################
# Load necessary jar files
##########################################################################################

Dir["#{Cantata.vendor_dir}/*.jar"].each do |jar|
  require jar
end

Dir["#{Cantata.target_dir}/*.jar"].each do |jar|
  require jar
end
