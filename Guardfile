ignore %r{^coverage/}
notification :terminal_notifier, activate: 'com.googlecode.iterm2'

group :server do
  guard :shotgun, server: 'puma', host: '0.0.0.0' do
    watch(/.+/) # watch *every* file in the directory
  end
end

group :test do
  # Note: The cmd option is now required due to the increasing number of ways
  #       rspec may be run, below are examples of the most common uses.
  #  * bundler: 'bundle exec rspec'
  #  * bundler binstubs: 'bin/rspec'
  #  * spring: 'bin/rsspec' (This will use spring if running and you have
  #                          installed the spring binstubs per the docs)
  #  * zeus: 'zeus rspec' (requires the server to be started separetly)
  #  * 'just' rspec: 'rspec'
  guard :rspec, cmd: 'bundle exec rspec' do
    watch(%r{^spec/.+_spec\.rb$})
    watch(%r{^lib/(.+)\.rb$}) { 'spec' }
    watch('spec/spec_helper.rb') { 'spec' }
    watch(%r{spec/support/(.+)\.rb}) { 'spec' }
  end
end