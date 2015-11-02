module Dome
  class Terraform
    include Dome::Shell

    attr_reader :state

    def initialize
      @environment = Dome::Environment.new
      @state       = Dome::State.new(@environment)
      @plan_file   = "plans/#{@environment.account}-#{@environment.environment}-plan.tf"
    end

    def validate_environment
      environment_name = @environment.environment
      account_name     = @environment.account
      @environment.invalid_account_message unless @environment.valid_account? account_name
      @environment.invalid_environment_message unless @environment.valid_environment?(account_name, environment_name)
      @environment.populate_aws_access_keys
    end

    def plan
      delete_terraform_directory
      delete_plan_file
      install_terraform_modules
      @state.synchronise_s3_state
      create_plan
    end

    def plan_destroy
      delete_terraform_directory
      delete_plan_file
      install_terraform_modules
      @state.synchronise_s3_state
      create_destroy_plan
    end

    def apply
      command         = "terraform apply #{@plan_file}"
      failure_message = 'something went wrong when applying the TF plan'
      execute_command(command, failure_message)
    end

    def create_plan
      command         = "terraform plan -module-depth=1 -refresh=true -out=#{@plan_file} -var-file=params/env.tfvars"
      failure_message = 'something went wrong when creating the TF plan'
      execute_command(command, failure_message)
    end

    def delete_terraform_directory
      puts 'Deleting older terraform module cache dir ...'.colorize(:green)
      terraform_directory = '.terraform'
      puts "About to delete directory: #{terraform_directory}"
      FileUtils.rm_rf '.terraform/'
    end

    def delete_plan_file
      puts 'Deleting older terraform plan ...'.colorize(:green)
      puts "About to delete: #{@plan_file}"
      FileUtils.rm_f @plan_file
    end

    def create_destroy_plan
      command         = "terraform plan -destroy -module-depth=1 -out=#{@plan_file} -var-file=params/env.tfvars"
      failure_message = 'something went wrong when creating the TF plan'
      execute_command(command, failure_message)
    end

    def install_terraform_modules
      command         = 'terraform get -update=true'
      failure_message = 'something went wrong when pulling remote TF modules'
      execute_command(command, failure_message)
    end
  end
end