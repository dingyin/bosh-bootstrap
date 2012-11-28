module Bosh::Bootstrap::Stages
  class MicroBoshDeploy
    attr_reader :settings

    def initialize(settings)
      @settings = settings
    end

    # TODO "aws_us_east_1" should come from settings.bosh_name
    def commands
      settings[:bosh_name] ||= "unnamed_bosh"

      @commands ||= Bosh::Bootstrap::Commander::Commands.new do |server|
        server.download "micro-bosh stemcell", script("download_micro_bosh_stemcell",
                      "MICRO_BOSH_STEMCELL_NAME" => settings.micro_bosh_stemcell_name)
        server.upload_file "/var/vcap/store/microboshes/#{settings.bosh_name}/micro_bosh.yml", micro_bosh_manifest
      end
    end

    private
    def stage_name
      "stage_micro_bosh_deploy"
    end

    # Loads local script
    # If +variables+, then injects KEY=VALUE environment
    # variables into bash scripts.
    def script(segment_name, variables={})
      path = File.expand_path("../#{stage_name}/#{segment_name}", __FILE__)
      if File.exist?(path)
        script = File.read(path)
        if variables.keys.size > 0
          inline_variables = "#!/usr/bin/env bash\n\n"
          variables.each { |name, value| inline_variables << "#{name}=#{value}\n" }
          script.gsub!("#!/usr/bin/env bash", inline_variables)
        end
        script
      else
        Thor::Base.shell.new.say_status "error", "Missing script lib/bosh-bootstrap/stages/#{stage_name}/#{segment_name}", :red
        exit 1
      end
    end

    def micro_bosh_manifest
      {}.to_yaml
    end
  end
end
