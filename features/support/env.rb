require 'rubygems'
LINE = "************************************************************"

def to_boolean(s)
  s and !!s.match(/^(true|yes|y|t)$/i)
end

def trim_newline (s)
   s.slice(0..s.size-2)
end



def random_str (size)
  string = (1..size.to_i-1).map { $o[rand($o.length)] }.join
  return "r#{string}"
end

def initialize_helpers ()

  filename = File.join Dir.pwd, 'default.json'
  $props = load_json(filename)
  puts "***** Runtime property values loaded from #{filename} *****"
  $props.each do |k,v|
    puts "Property #{k}=[#{v}]"
  end
  puts LINE

  $bridge = empty_bridge
  setup_random_chars
end

def setup_random_chars
  #generate some random characters to use for test names
  $o = Array.new

  for i in 20 .. 1024
    $o << (i.chr 'utf-8')
  end
end

def empty_bridge()
  {'stats' => {}, 'jobs' => {}, 'hashes' => {}, 'internal' => {'count' => 0, 'times' => []}}
end

def load_json (file_name)
  begin
    obj = JSON.parse (File.read file_name)
  rescue Exception => e
    obj = Hash.new
    obj['error_message'] = e.message
  end

  return obj
end

def local_gems
  Gem::Specification.sort_by{ |g| [g.name.downcase, g.version] }.group_by{ |g| g.name }
end

def echo_environment
  puts LINE
  puts "Ruby version #{RUBY_VERSION}"
  puts "Operating System #{RUBY_PLATFORM}"
  puts local_gems.map{ |name, specs|
    [
        name,
        specs.map{ |spec| spec.version.to_s }.join(',')
    ].join(' ')
  }
  puts LINE
end

initialize_helpers
echo_environment
puts 'One time setup from env.rb complete'
