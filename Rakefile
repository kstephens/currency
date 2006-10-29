# Rakefile for currency      -*- ruby -*-
# Adapted from RubyGems/Rakefile
# upload_package NOT WORKING YET

#require 'rubygems'
require 'rake/clean'
require 'rake/testtask'
require 'rake/packagetask'
require 'rake/gempackagetask'
require 'rake/rdoctask'

def announce(msg='')
  STDERR.puts msg
end

PKG_Name = 'Currency'
PKG_NAME = PKG_Name.gsub(/[a-z][A-Z]/) {|x| "#{x[0,1]}_#{x[1,1]}"}.downcase
RUBY_FORGE_PROJECT = PKG_NAME

def package_version
  '0.1.0'
end

if ENV['REL']
  PKG_VERSION = ENV['REL']
  CURRENT_VERSION = package_version
else
  PKG_VERSION = package_version
  CURRENT_VERSION = PKG_VERSION
end

CLEAN.include("COMMENTS")
CLOBBER.include(
  "test/data",
  "test/temp",
  'scripts/*.hieraki',
  'data__',
  'html',
  'pkgs/sources/sources*.gem',
  '.config',
  '**/debug.log',
  '**/development.log',
  'logs'
  )

task :default => [:test]

Rake::TestTask.new(:test) do |t|
  t.test_files = FileList['test/*test*.rb']
end

Rake::TestTask.new(:functional) do |t|
  t.test_files = FileList['test/functional*.rb']
end

Rake::TestTask.new(:alltests) do |t|
  t.test_files = FileList['test/{*test,functional}*.rb']
end

desc "Run the tests for a build"
task :build_tests do
  html_dir = ENV['TESTRESULTS'] || 'html/tests'
  ruby %{-Ilib scripts/buildtests.rb #{html_dir}}
  open("#{html_dir}/summary.html") do |inf|
    open("#{html_dir}/summary.new", "w") do |outf|
      inf.each do |line|
	if line =~ /td align/
	  line = "    <td align=\"left\">#{Time.now}</td><td align=\"right\">"
	end
	outf.puts line
      end
    end
  end
  mv "#{html_dir}/summary.html", "#{html_dir}/summary.old"
  mv "#{html_dir}/summary.new", "#{html_dir}/summary.html"      
end

# Shortcuts for test targets
task :tf => [:functional]
task :tu => [:test]
task :ta => [:alltests]

task :gemtest do
  ruby %{-Ilib -rscripts/runtest -e 'run_tests("test/test_gempaths.rb", true)'}
end

# --------------------------------------------------------------------
# Creating a release

desc "Make a new release"
task :release => [
  :prerelease,
  :clobber,
  :alltests,
  :update_version,
  :package,
  :tag] do
  
  announce 
  announce "**************************************************************"
  announce "* Release #{PKG_VERSION} Complete."
  announce "* Packages ready to upload."
  announce "**************************************************************"
  announce 
end

# Validate that everything is ready to go for a release.
task :prerelease do
  announce 
  announce "**************************************************************"
  announce "* Making #{PKG_Name} Release #{PKG_VERSION}"
  announce "* (current version #{CURRENT_VERSION})"
  announce "**************************************************************"
  announce  

  # Is a release number supplied?
  unless ENV['REL']
    fail "Usage: rake release REL=x.y.z [REUSE=tag_suffix]"
  end

  # Is the release different than the current release.
  # (or is REUSE set?)
  if PKG_VERSION == CURRENT_VERSION && ! ENV['REUSE']
    fail "Current version is #{PKG_VERSION}, must specify REUSE=tag_suffix to reuse version"
  end

  # Are all source files checked in?
  if ENV['RELTEST']
    announce "Release Task Testing, skipping checked-in file test"
  else
    announce "Checking for unchecked-in files..."
    data = `svn status`
    unless data =~ /^$/
      fail "svn status is not clean ... do you have unchecked-in files?"
    end
    announce "No outstanding checkins found ... OK"
  end
end

task :update_version => [:prerelease] do
  if PKG_VERSION == CURRENT_VERSION && ! ENV['FORCE']
    announce "No version change ... skipping version update"
  else
    announce "Updating #{PKG_Name} version to #{PKG_VERSION}"
    version_rb = "lib/#{PKG_NAME}/#{PKG_NAME}_version.rb"
    open(version_rb, "w") do |f|
      f.puts "# DO NOT EDIT"
      f.puts "# This file is auto-generated by build scripts."
      f.puts "# See:  rake update_version"
      f.puts "module #{PKG_Name}"
      f.puts "  #{PKG_Name}Version = '#{PKG_VERSION}'"
      f.puts "end"
    end
    if ENV['RELTEST']
      announce "Release Task Testing, skipping commiting of new version"
    else
      sh %{svn commit -m "Updated to version #{PKG_VERSION}" #{version_rb}}
    end
  end
end

# FIX ME for SVN
task :tag => [:prerelease] do
  reltag = "REL_#{PKG_VERSION.gsub(/\./, '_')}"
  reltag << ENV['REUSE'].gsub(/\./, '_') if ENV['REUSE']
  announce "Tagging repo with [#{reltag}]"
  if ENV['RELTEST']
    announce "Release Task Testing, skipping repo tagging"
  else
    sh %{echo cvs tag #{reltag}}
  end
end

# --------------------------------------------------------------------
# Create a task to build the RDOC documentation tree.

desc "Create the RDOC html files"
rd = Rake::RDocTask.new("rdoc") { |rdoc|
  rdoc.rdoc_dir = 'html'
  rdoc.title    = "#{PKG_Name}"
  rdoc.options << '--line-numbers' << '--inline-source' << '--main' << 'README'
  rdoc.rdoc_files.include('README', 'TODO', 'Releases')
  rdoc.rdoc_files.include('lib/**/*.rb')
#  rdoc.rdoc_files.include('test/**/*.rb')
}

file "html/index.html" => [:rdoc]

desc "Publish the RDOCs on RubyForge"
task :publish_rdoc => ["html/index.html"] do
  # NOTE: This task assumes that you have an SSH alias setup for rubyforge.
  mkdir_p "emptydir"
  sh "scp -rq emptydir rubyforge:/var/www/gforge-projects/#{RUBY_FORGE_PROJECT}/rdoc"
  sh "scp -rq html/* rubyforge:/var/www/gforge-projects/#{RUBY_FORGE_PROJECT}/rdoc"
  rm_r "emptydir"
end

# Wiki Doc Targets

desc "Upload the Hieraki Data"
task :upload => [:upload_gemdoc]

task :upload_gemdoc => ['scripts/gemdoc.hieraki'] do
  ruby %{scripts/upload_gemdoc.rb}
end

desc "Build the Hieraki documentation"
task :hieraki => ['scripts/gemdoc.hieraki', 'scripts/specdoc.hieraki']

file 'scripts/gemdoc.hieraki' => ['scripts/gemdoc.rb', 'scripts/gemdoc.data'] do
  chdir('scripts') do
    ruby %{-I../lib gemdoc.rb <gemdoc.data >gemdoc.hieraki}
  end
end

file 'scripts/specdoc.hieraki' =>
  ['scripts/specdoc.rb', 'scripts/specdoc.data', 'scripts/specdoc.yaml'] do
  chdir('scripts') do
    ruby %{-I../lib specdoc.rb >specdoc.hieraki}
  end
end

# Package tasks

PKG_FILES = FileList[
  "Rakefile", "ChangeLog", "Releases", "TODO", "README", 
#  "setup.rb",
#  "post-install.rb",
  "bin/*",
  "doc/*.css", "doc/*.rb",
  "examples/**/*",
#  "gemspecs/**/*",
  "lib/**/*.rb",
#  "pkgs/**/*",
  "redist/*.gem",
  "scripts/*.rb",
  "test/**/*"
]
PKG_FILES.exclude(%r(^(test/temp|examples/.*/*.log)(/|$)))

Rake::PackageTask.new("package") do |p|
  p.name = PKG_NAME
  p.version = PKG_VERSION
  p.need_tar = true
  p.need_zip = true
  p.package_files = PKG_FILES
end

Spec = Gem::Specification.new do |s|
  s.name = PKG_NAME 
  s.version = PKG_VERSION
  s.summary = "#{PKG_Name} GEM"
  s.description = %{Currency models currencies, monetary values, foreign exchanges.
}
  s.files = PKG_FILES.to_a
  s.require_path = 'lib'
  s.author = "Kurt Stephens"
  s.email = "ruby-#{PKG_NAME}@umleta.com"
  s.homepage = "http://#{PKG_NAME}.rubyforge.org"
  s.rubyforge_project = "#{RUBY_FORGE_PROJECT}"
  #s.bindir = "bin"                               # Use these for applications.
  #s.executables = ["update_rubygems"]
  certdir = ENV['CERT_DIR']
  if certdir
    s.signing_key = File.join(certdir, 'gem-umleta-private_key.pem')
    s.cert_chain  = [File.join(certdir, 'gem-umleta-public_cert.pem')]
  end
end

# Add console output about signing the Gem
file "pkg/#{Spec.full_name}.gem" do
  puts "Signed with certificates in '#{ENV['CERT_DIR']}'" if ENV['CERT_DIR']
end

Rake::GemPackageTask.new(Spec) do |p| end

GEMSPEC = "pkg/#{PKG_NAME}.gemspec"
desc "Build the Gem spec file for the #{PKG_NAME} package"
task :gemspec => GEMSPEC
file "pkg/#{PKG_NAME}.gemspec" => ["pkg", "Rakefile"] do |t|
  open(t.name, "w") do |f| f.puts Spec.to_yaml end
end

# Automated upload to rubyforge.org
PACKAGE_FILES = FileList["pkg/#{PKG_NAME}-#{PKG_VERSION}.*"]
task :upload_package do
# From activesuport/Rakefile, 
# See: http://dev.rubyonrails.org/svn/rails/tags/rel_1-1-6/activesupport/Rakefile
  `rubyforge login`

  files = PACKAGE_FILES
  files.each do |filename|
    basename  = File.basename(filename)
    puts "Releasing #{basename}..."
    
    release_command = "rubyforge add_release #{RUBY_FORGE_PROJECT} #{RUBY_FORGE_PROJECT} 'REL #{PKG_VERSION}' #{filename}"
    puts release_command
    system(release_command)
  end
end


desc "Install #{PKG_Name}"
task :install do
  ruby 'install.rb'
end

# Run 'gem' (using local bin and lib directories).
# e.g.
#     rake rungem -- install -r blahblah --test

desc "Run local 'gem'"
task :rungem do
  ARGV.shift
  exec "ruby -Ilib bin/gem #{ARGV.join(' ')}"
end

# Misc Tasks ---------------------------------------------------------

def egrep(pattern)
  Dir['**/*.rb'].each do |fn|
    count = 0
    open(fn) do |f|
      while line = f.gets
	count += 1
	if line =~ pattern
	  puts "#{fn}:#{count}:#{line}"
	end
      end
    end
  end
end

desc "Look for TODO and FIXME tags in the code"
task :todo do
  egrep /#.*(FIXME|TODO|TBD)/
end

desc "Look for Debugging print lines"
task :dbg do
  egrep /\bDBG|\bbreakpoint\b/
end

desc "List all ruby files"
task :rubyfiles do 
  puts Dir['**/*.rb'].reject { |fn| fn =~ /^pkg/ }
  puts Dir['bin/*'].reject { |fn| fn =~ /CVS|.svn|(~$)|(\.rb$)/ }
end

