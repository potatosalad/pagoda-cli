module Pagoda
  module Helpers
    INDENT = "  "
    
    def home_directory
      running_on_windows? ? ENV['USERPROFILE'] : ENV['HOME']
    end

    def running_on_windows?
      RUBY_PLATFORM =~ /mswin32|mingw32/
    end

    def running_on_a_mac?
      RUBY_PLATFORM =~ /-darwin\d/
    end

    def display(msg="", newline=true, level=1)
      indent = build_indent(level)
      if newline
        (running_on_windows?) ? puts("#{indent}#{msg}") : puts("#{indent}#{msg}".green)
      else
        (running_on_windows?) ? print("#{indent}#{msg}") : print("#{indent}#{msg}".green)
        STDOUT.flush
      end
    end
    
    def option_value(short_hand = nil, long_hand = nil)
      match = false
      value = nil
      
      if short_hand
        if ARGV.include?(short_hand)
          value = ARGV[ARGV.index(short_hand) + 1]
          match = true
        end
      end
      if long_hand && !match
        if match = ARGV.grep(/#{long_hand}.*/).first
          if match.include? "="
            value = match.split("=").last
          else
            value = true
          end
        end
      end
      
      value
    end

    def format_date(date)
      date = Time.parse(date) if date.is_a?(String)
      date.strftime("%Y-%m-%d %H:%M %Z")
    end

    def ask(message=nil, level=1)
      display("#{message}", false, level) if message
      STDIN.gets.strip
    end
    
    def confirm(message="Are you sure you wish to continue? (y/n)?", level=1)
      return true if ARGV.include? "-f"
      case message
      when Array
        count = message.length
        iteration = 0
        message.each do |m|
          if iteration == count - 1
            (running_on_windows?) ? display("#{m} ", false, level) : display("#{m} ".blue, false, level)
          else
            (running_on_windows?) ? display("#{m} ", false, level) : display("#{m} ".blue, true, level)
          end
          iteration += 1
        end
      when String
        (running_on_windows?) ? display("#{message} ", false, level) : display("#{message} ".blue, false, level)
      end
      ask.downcase == 'y'
    end

    def error(msg, exit=true, level=1)
      indent = build_indent(level)
      STDERR.puts
      case msg
      when Array
        (running_on_windows?) ? STDERR.puts("#{indent}** Error:") : STDERR.puts("#{indent}** Error:".red)
        msg.each do |m|
          (running_on_windows?) ? STDERR.puts("#{indent}** #{m}") : STDERR.puts("#{indent}** #{m}".red)
        end
      when String
        (running_on_windows?) ? STDERR.puts("#{indent}** Error: #{msg}") : STDERR.puts("#{indent}** Error: #{msg}".red)
      end
      STDERR.puts
      exit 1 if exit
    end
    
    # def loop_transaction(app_name = nil)
    #   finished = false
    #   until finished
    #     display ".", false, 0
    #     sleep 1
    #     if client.app_info(app_name || app)[:transactions].count < 1
    #       finished = true
    #       display
    #     end
    #   end
    # end

    def has_git?
      %x{ git --version }
      $?.success?
    end

    def git(args)
      return "" unless has_git?
      flattened_args = [args].flatten.compact.join(" ")
      %x{ git #{flattened_args} 2>&1 }.strip
    end


    def create_git_remote(id, remote)
      error "you do not have git installed on your computer" unless has_git?
      error "this remote is already in use on this repo" if git('remote').split("\n").include?(remote)
      error(["repo has not been initialized." , "try 'git init'"]) unless File.directory?(".git")
      git "remote add #{remote} git@pagodabox.com:#{id}.git"
      git "config --add pagoda.id #{id}"
      display "Git remote #{remote} added"
    end

    def build_indent(level=1)
      indent = ""
      level.times do
        indent += INDENT
      end
      indent
    end
    
  end
end