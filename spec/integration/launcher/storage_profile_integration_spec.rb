require 'spec_helper'

describe Vcloud::Launcher::Launch do
  context "storage profile", :take_too_long => true do
    before(:all) do
      @data_dir = File.join(File.dirname(__FILE__), "/data")
      @test_data = define_test_data
      @config_yaml = ErbHelper.convert_erb_template_to_yaml(@test_data, File.join(File.dirname(__FILE__), 'data/storage_profile.yaml.erb'))
      @fog_interface = Vcloud::Fog::ServiceInterface.new
      Vcloud::Launcher::Launch.new.run(@config_yaml, {'dont-power-on' => true})

      @vapp_query_result_1 = @fog_interface.get_vapp_by_name_and_vdc_name(@test_data[:vapp_name_1], @test_data[:vdc_1_name])
      @vapp_id_1 = @vapp_query_result_1[:href].split('/').last
      @vapp_1 = @fog_interface.get_vapp @vapp_id_1
      @vm_1 = @vapp_1[:Children][:Vm].first

      @vapp_query_result_2 = @fog_interface.get_vapp_by_name_and_vdc_name(@test_data[:vapp_name_2], @test_data[:vdc_2_name])
      @vapp_id_2 = @vapp_query_result_2[:href].split('/').last
      @vapp_2 = @fog_interface.get_vapp @vapp_id_2
      @vm_2 = @vapp_2[:Children][:Vm].first

      @vapp_query_result_3 = @fog_interface.get_vapp_by_name_and_vdc_name(@test_data[:vapp_name_3], @test_data[:vdc_1_name])
      @vapp_id_3 = @vapp_query_result_3[:href].split('/').last
      @vapp_3 = @fog_interface.get_vapp @vapp_id_3
      @vm_3 = @vapp_3[:Children][:Vm].first

      @vapp_query_result_4 = @fog_interface.get_vapp_by_name_and_vdc_name(@test_data[:vapp_name_4], @test_data[:vdc_1_name])
      @vapp_id_4 = @vapp_query_result_4[:href].split('/').last
      @vapp_4 = @fog_interface.get_vapp @vapp_id_4
      @vm_4 = @vapp_4[:Children][:Vm].first
    end

    it "vdc 1 should have a storage profile without the href being specified" do
        @vm_1[:StorageProfile][:name].should == @test_data[:storage_profile]
    end

    it "vdc 1's storage profile should have the expected href" do
        @vm_1[:StorageProfile][:href].should == @test_data[:vdc_1_sp_href]
    end

    it "vdc 2 should have the same named storage profile as vdc 1" do
        @vm_2[:StorageProfile][:name].should == @test_data[:storage_profile]
    end

    it "the storage profile in vdc 2 should have a different href to the storage profile in vdc 1" do
        @vm_2[:StorageProfile][:href].should == @test_data[:vdc_2_sp_href]
    end

    it "when a storage profile is not specified, vm uses the default and continues" do
        @vm_3[:StorageProfile][:name].should == @test_data[:default_storage_profile_name]
        @vm_3[:StorageProfile][:href].should == @test_data[:default_storage_profile_href]
    end

   it "when a storage profile is not specified, customize continues with other customizations" do
        @vm_3_id = @vm_3[:href].split('/').last
        @vm_3_metadata = Vcloud::Core::Vm.get_metadata @vm_3_id
        @vm_3_metadata[:storage_profile_test_vm].should == true
    end

    it "when a storage profile specified does not exist, vm uses the default" do
        @vm_4[:StorageProfile][:name].should == @test_data[:default_storage_profile_name]
        @vm_4[:StorageProfile][:href].should == @test_data[:default_storage_profile_href]
    end

    # This is a bug - if it has failed customization it should let the user know
    it "when storage profile specified doesn't exist, it errors and continues" do
        @vm_4_id = @vm_4[:href].split('/').last
        @vm_4_metadata = Vcloud::Core::Vm.get_metadata @vm_4_id
        @vm_4_metadata[:storage_profile_test_vm].should be_nil
    end

    after(:all) do
      unless ENV['VCLOUD_TOOLS_RSPEC_NO_DELETE_VAPP']
        File.delete @config_yaml
        @fog_interface.delete_vapp(@vapp_id_1).should == true
        @fog_interface.delete_vapp(@vapp_id_2).should == true
        @fog_interface.delete_vapp(@vapp_id_3).should == true
        @fog_interface.delete_vapp(@vapp_id_4).should == true
      end
    end

  end

end

def define_test_data
  parameters = Vcloud::Tools::Tester::
    TestParameters.new("#{@data_dir}/vcloud_tools_testing_config.yaml")
  {
      vapp_name_1: "vdc-1-sp-#{Time.now.strftime('%s')}",
      vapp_name_2: "vdc-2-sp-#{Time.now.strftime('%s')}",
      vapp_name_3: "vdc-3-sp-#{Time.now.strftime('%s')}",
      vapp_name_4: "vdc-4-sp-#{Time.now.strftime('%s')}",
      vdc_1_name: parameters.vdc_1_name,
      vdc_2_name: parameters.vdc_2_name,
      catalog: parameters.catalog,
      vapp_template: parameters.catalog_item,
      storage_profile: parameters.storage_profile,
      vdc_1_sp_href: parameters.vdc_1_storage_profile_href,
      vdc_2_sp_href: parameters.vdc_2_storage_profile_href,
      default_storage_profile_name: parameters.default_storage_profile_name,
      default_storage_profile_href: parameters.default_storage_profile_href,
      nonsense_storage_profile: "nonsense-storage-profile-name",
      bootstrap_script: File.join(File.dirname(__FILE__), "data/basic_preamble_test.erb"),
  }
end
