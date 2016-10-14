
require "net/http"

module CogCmd
  module Imbriaco
    class Exec < Cog::Command
      def run_command
        action = request.args[0]
        response["title"] = [ "imbriaco:exec", action ].join(" ")

        if action.nil?
          response.template = "body_plain"
          response["body"] = "No action specified."
        elsif !self.respond_to?(action.to_sym)
          response.template = "body_plain"
          response["body"] = "No #{action} method found for #{self.class}."
        else
          self.send(action.to_sym)
        end
      end

      def env
        response.template = "body_raw"
        response["body"] = ENV.map { |k,v| "%-25s %s" % [k, v] }.sort.join("\n")
      end

      def service
        path = request.args[1]

        headers = {
          "Authorization" => "pipeline #{ENV['COG_SERVICE_TOKEN']}",
          "Content-Type"  => "application/json"
        }

        uri = URI(ENV["COG_SERVICES_ROOT"] + "/v1/services" + path)
        res = Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == "https") do |http|
          req = Net::HTTP::Get.new(uri)
          headers.each { |k,v| req[k] = v }
          res = http.request(req)

          body =
            begin
              JSON.pretty_generate(JSON.parse(res.body))
            rescue
              res.body
            end

          response.template = "service"
          response["url"] = res.uri
          response["headers"] = res.to_hash.map { |k,v| "%-25s %s" % [k, v] }.sort.join("\n")
          response["body"] = body
        end
      end
    end
  end
end
