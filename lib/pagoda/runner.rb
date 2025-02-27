require 'rest-client'

module Pagoda
  class Runner

# DO NOT PUT A LOOP IN THE ARRAY ie ( cows => horse, horse => cows) <= will break for sure
    ALIAS = {
                "apps" => "app",
                'db' => "mysql",
                "sharing" => "collaborator"
              }

    class InvalidCommand < RuntimeError; end
    
    extend Pagoda::Helpers
    
    class << self
      
      def go(command, args, retries=0)
        begin
          Pagoda::Auth.credentials
          run_internal(command, args.dup)
        rescue InvalidCommand
          error "Unknown command: #{command}. Run 'pagoda help' for usage information."
        rescue RestClient::Unauthorized
          if retries < 3
            STDERR.puts "Authentication failure"
            go(command, args, retries+1)
          else
            error "Authentication failure"
          end
        rescue RestClient::ResourceNotFound => e
          error extract_not_found(e.http_body)
        rescue RestClient::RequestFailed => e
          error extract_error(e.http_body) unless e.http_code == 402 || e.http_code == 102
        rescue RestClient::RequestTimeout
          error "API request timed out. Please try again, or contact support@pagodabox.com if this issue persists."
        # rescue CommandFailed => e
          # error e.message
        rescue Interrupt => e
          error "\n[canceled]"
        end
      end

      def run_internal(command, args)
        klass, method = parse(command)
        runner = klass.new(args)
        raise InvalidCommand unless runner.respond_to?(method)
        runner.send(method)
      end

      def parse(command)
        parts = command.split(':')
        case parts.size
          when 1
            begin
              return eval("Pagoda::Command::#{command.capitalize}"), :index
            rescue NameError, NoMethodError
              if vintage_command = ALIAS[command]
                return parse(vintage_command)
              end
              return Pagoda::Command::App, command.to_sym
            end
          else
            begin
              const = Pagoda::Command
              command = parts.pop
              parts.each { |part| const = const.const_get(part.capitalize) }
              return const, command.to_sym
            rescue NameError
              if parts[0] = ALIAS[parts[0]]  # ADD VINTAGE STUFF
                return parse(parts.join(":") << ":" << command)
              end
              raise InvalidCommand
            end
        end
      end

      def extract_not_found(body)
        body =~ /^[\w\s]+ not found$/ ? body : "Resource not found"
      end

      def extract_error(body)
        msg = parse_error_xml(body) || parse_error_json(body) || 'Internal server error'
      end

      def parse_error_xml(body)
        xml_errors = REXML::Document.new(body).elements.to_a("//errors/error")
        msg = xml_errors.map { |a| a.text }.join(" / ")
        return msg unless msg.empty?
      rescue Exception
      end
      
      def parse_error_json(body)
        json = JSON.parse(body.to_s)
        json['error']
      rescue JSON::ParserError
      end



      
    end
  end  
end
