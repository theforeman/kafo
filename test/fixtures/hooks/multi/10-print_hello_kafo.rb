boot do
  app_option('--print-hello-kafo', :flag, 'Prints Hello Kafo when run is complete')
end

post('11-print_goodbye') do
  puts "Goodbye"
end

post do
  if app_value(:print_hello_kafo)
    puts "Hello Kafo"
  end
end
