def brew_update
  abort "Please `brew install git' first." unless system "/usr/bin/which -s git"

  require 'update'
  updater = RefreshBrew.new
  unless updater.update_from_masterbrew!
    puts "Already up-to-date."
  else
    updater.report
  end
end