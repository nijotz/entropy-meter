require File.expand_path('../../lib/entropy.rb', __FILE__)

SCHEDULER.every '60m', :first_in => 0 do
  send_event('entropy',   { value: get_entropy() })
end
