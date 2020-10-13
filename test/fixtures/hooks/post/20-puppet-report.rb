say "Puppet report format: #{puppet_report&.report_format}"

puppet_report&.failed_resources&.each do |failed_resource|
  say "#{failed_resource} failed. Logs:"
  failed_resource.log_messages.each do |message|
    say message
  end
end
