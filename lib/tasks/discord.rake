namespace :discord do
  desc "Start the Discord sentiment listener"
  task listen: :environment do
    # This prevents the task from exiting immediately
    DiscordListenerService.new.start!
  end
end