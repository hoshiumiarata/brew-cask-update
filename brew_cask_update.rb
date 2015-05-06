require 'optparse'
require 'fileutils'

CASK_PATH = '/usr/local/bin/brew-cask'
CASKROOM = '/opt/homebrew-cask/Caskroom'

class Cask
  def self.outdated_packages
    installed_vers = installed_versions
    last_versions.select { |app, ver| !installed_vers[app].include?(ver) }
      .map { |app, _| app }
  end

  def self.apps
    `#{CASK_PATH} list`.split
  end

  def self.last_versions
    Hash[apps.map do |app|
      [app, `#{CASK_PATH} info #{app}`.scan(/#{app}: (.*)/)[0][0]]
    end]
  end

  def self.installed_versions
    Hash[apps.map do |app|
      [app, Dir["#{CASKROOM}/#{app}/*"].map { |ver| File.basename ver }]
    end]
  end

  def self.update
    system("#{CASK_PATH} update")
  end

  def self.upgrade
    outdated_packages.each do |app, _|
      system("#{CASK_PATH} install #{app}")
    end
  end

  def self.old_packages
    last_vers = last_versions
    Hash[installed_versions.map { |app, vers| [app, vers - [last_vers[app]]] }
      .select { |_, vers| vers.size > 0 }]
  end

  # A little shitty
  def self.cleanup
    to_delete = Cask.old_packages.map do |app, vers|
      vers.map { |ver| "#{CASKROOM}/#{app}/#{ver}/" }
    end.flatten
    return if to_delete.empty?
    puts 'Directories to delete:'
    puts to_delete
    puts 'Continue? (y/n)'
    to_delete.each { |dir| FileUtils.rm_rf dir } if gets =~ /^y/
  end
end

OptionParser.new do |opts|
  opts.on('--outdated', 'List of outdated packages') do
    puts Cask.outdated_packages
  end

  opts.on('--update', 'Update packages') do
    Cask.update
  end

  opts.on('--upgrade', 'Upgrade packages') do
    Cask.upgrade
  end

  opts.on('--old-packages', '-o', 'Old packages') do
    Cask.old_packages.each { |app, vers| puts "#{app}\t#{vers.join(', ')}" }
  end

  opts.on('--cleanup', 'Remove old packages') do
    Cask.cleanup
  end

  opts.on_tail('--help', '-h', 'Show help') do
    puts opts
  end
end.parse!
