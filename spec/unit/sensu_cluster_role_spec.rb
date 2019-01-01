require 'spec_helper'
require 'puppet/type/sensu_cluster_role'

describe Puppet::Type.type(:sensu_cluster_role) do
  let(:default_config) do
    {
      name: 'test',
      rules: [{'verbs' => ['get','list'], 'resources' => ['checks']}]
    }
  end
  let(:config) do
    default_config
  end
  let(:cluster_role) do
    described_class.new(config)
  end

  it 'should add to catalog without raising an error' do
    catalog = Puppet::Resource::Catalog.new
    expect {
      catalog.add_resource cluster_role
    }.to_not raise_error
  end

  it 'should require a name' do
    expect {
      described_class.new({})
    }.to raise_error(Puppet::Error, 'Title or name must be provided')
  end

  defaults = {
  }

  # String properties
  [
  ].each do |property|
    it "should accept valid #{property}" do
      config[property] = 'foo'
      expect(cluster_role[property]).to eq('foo')
    end
    if default = defaults[property]
      it "should have default for #{property}" do
        expect(cluster_role[property]).to eq(default)
      end
    end
  end

  # String regex validated properties
  [
  ].each do |property|
    it "should not accept invalid #{property}" do
      config[property] = 'foo bar'
      expect { cluster_role }.to raise_error(Puppet::Error, /#{property.to_s} invalid/)
    end
  end

  # Array properties
  [
  ].each do |property|
    it "should accept valid #{property}" do
      config[property] = ['foo', 'bar']
      expect(cluster_role[property]).to eq(['foo', 'bar'])
    end
  end

  # Integer properties
  [
  ].each do |property|
    it "should accept valid #{property}" do
      config[property] = 30
      expect(cluster_role[property]).to eq(30)
    end
    it "should accept valid #{property} as string" do
      config[property] = '30'
      expect(cluster_role[property]).to eq(30)
    end
    it "should not accept invalid value for #{property}" do
      config[property] = 'foo'
      expect { cluster_role }.to raise_error(Puppet::Error, /should be an Integer/)
    end
  end

  # Boolean properties
  [
  ].each do |property|
    it "should accept valid #{property}" do
      config[property] = true
      expect(cluster_role[property]).to eq(:true)
    end
    it "should accept valid #{property}" do
      config[property] = false
      expect(cluster_role[property]).to eq(:false)
    end
    it "should accept valid #{property}" do
      config[property] = 'true'
      expect(cluster_role[property]).to eq(:true)
    end
    it "should accept valid #{property}" do
      config[property] = 'false'
      expect(cluster_role[property]).to eq(:false)
    end
    it "should not accept invalid #{property}" do
      config[property] = 'foo'
      expect { cluster_role }.to raise_error(Puppet::Error, /Invalid value "foo". Valid values are true, false/)
    end
  end

  # Hash properties
  [
  ].each do |property|
    it "should accept valid #{property}" do
      config[property] = { 'foo': 'bar' }
      expect(cluster_role[property]).to eq({'foo': 'bar'})
    end
    it "should not accept invalid #{property}" do
      config[property] = 'foo'
      expect { cluster_role }.to raise_error(Puppet::Error, /should be a Hash/)
    end
  end

  describe 'rules' do
    it 'accepts valid value' do
      expect(cluster_role[:rules]).to eq([{'verbs' => ['get','list'], 'resources' => ['checks'], 'resource_names' => nil}])
    end

    it 'accepts valid value' do
      config[:rules] = [{'verbs' => ['get','list'], 'resources' => ['checks'], 'resource_names' => ['test']}]
      expect(cluster_role[:rules]).to eq([{'verbs' => ['get','list'], 'resources' => ['checks'], 'resource_names' => ['test']}])
    end

    it 'should verify rule is a hash' do
      config[:rules] = ['foo']
      expect { cluster_role }.to raise_error(Puppet::Error, /Each rule must be a Hash/)
    end

    it 'should verify all keys present' do
      config[:rules] = [{'verbs' => ['get','list']}]
      expect { cluster_role }. to raise_error(Puppet::Error, /A rule must contain resources/)
    end

    it 'should not allow unknown keys' do
      config[:rules] = [{'verbs' => ['get','list'], 'resources' => ['checks'], 'resource_names' => [''], 'foo' => 'bar'}]
      expect { cluster_role }. to raise_error(Puppet::Error, /Rule key foo is not valid/)
    end

    it 'should verify permissions is an array' do
      config[:rules] = [{'verbs' => ['get','list'], 'resources' => ['checks'], 'resource_names' => ''}]
      expect { cluster_role }. to raise_error(Puppet::Error, /Rule's resource_names must be an Array/)
    end
  end

  it 'should autorequire Package[sensu-go-cli]' do
    package = Puppet::Type.type(:package).new(:name => 'sensu-go-cli')
    catalog = Puppet::Resource::Catalog.new
    catalog.add_resource cluster_role
    catalog.add_resource package
    rel = cluster_role.autorequire[0]
    expect(rel.source.ref).to eq(package.ref)
    expect(rel.target.ref).to eq(cluster_role.ref)
  end

  it 'should autorequire Service[sensu-backend]' do
    service = Puppet::Type.type(:service).new(:name => 'sensu-backend')
    catalog = Puppet::Resource::Catalog.new
    catalog.add_resource cluster_role
    catalog.add_resource service
    rel = cluster_role.autorequire[0]
    expect(rel.source.ref).to eq(service.ref)
    expect(rel.target.ref).to eq(cluster_role.ref)
  end

  it 'should autorequire Exec[sensuctl_configure]' do
    exec = Puppet::Type.type(:exec).new(:name => 'sensuctl_configure', :command => '/usr/bin/sensuctl')
    catalog = Puppet::Resource::Catalog.new
    catalog.add_resource cluster_role
    catalog.add_resource exec
    rel = cluster_role.autorequire[0]
    expect(rel.source.ref).to eq(exec.ref)
    expect(rel.target.ref).to eq(cluster_role.ref)
  end

  it 'should autorequire sensu_api_validator' do
    validator = Puppet::Type.type(:sensu_api_validator).new(:name => 'sensu')
    catalog = Puppet::Resource::Catalog.new
    catalog.add_resource cluster_role
    catalog.add_resource validator
    rel = cluster_role.autorequire[0]
    expect(rel.source.ref).to eq(validator.ref)
    expect(rel.target.ref).to eq(cluster_role.ref)
  end

  [
    :rules,
  ].each do |property|
    it "should require property when ensure => present" do
      config.delete(property)
      config[:ensure] = :present
      expect { cluster_role }.to raise_error(Puppet::Error, /You must provide a #{property}/)
    end
  end
end