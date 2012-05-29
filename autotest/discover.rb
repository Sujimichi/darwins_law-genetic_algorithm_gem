Autotest.add_discovery { "rspec2" }
#Autotest.options[:no_full_after_failed] = true

Autotest.add_hook :initialize do |at|
  at.add_mapping(%r%^lib/**/*.rb$%) {|filename, _|
    at.files_matching filename
  }
end

