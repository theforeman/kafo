namespace :jenkins do
  task :unit => ['jenkins:setup', 'test:unit', 'test:puppet_modules', 'test:acceptance']

  task :setup do
    ENV['MINITEST_REPORTER'] ||= 'JUnitReporter'
    ENV['MINITEST_REPORTERS_REPORTS_DIR'] ||= 'jenkins/reports/unit/'
  end
end
