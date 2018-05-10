require 'spec_helper'

describe 'tomcat::jar', type: :define do
  let :pre_condition do
    'class { "tomcat": }'
  end
  let :facts do
    {
      osfamily: 'Debian',
    }
  end
  let :title do
    'sample.jar'
  end

  context 'basic deployment' do
    let :params do
      {
        jar_source: '/tmp/sample.jar',
      }
    end

    it {
      is_expected.to contain_archive('tomcat::jar sample.jar').with(
        'source' => '/tmp/sample.jar',
        'path'   => '/opt/apache-tomcat/lib/sample.jar',
      )
    }
    it {
      is_expected.to contain_file('tomcat::jar sample.jar').with(
        'ensure' => 'file', 'path' => '/opt/apache-tomcat/lib/sample.jar',
        'owner' => 'tomcat', 'group' => 'tomcat', 'mode' => '0640'
      ).that_subscribes_to('Archive[tomcat::jar sample.jar]')
    }
  end
  context 'basic undeployment' do
    let :params do
      {
        jar_ensure: 'absent',
      }
    end

    it {
      is_expected.to contain_file('/opt/apache-tomcat/lib/sample.jar').with(
        'ensure' => 'absent',
        'force'  => 'false',
      )
    }
    it {
      is_expected.to contain_file('/opt/apache-tomcat/lib/sample').with(
        'ensure' => 'absent',
        'force'  => 'true',
      )
    }
  end
  context 'set everything' do
    let :params do
      {
        catalina_base: '/opt/apache-tomcat/test',
        jar_base: 'lib2',
        jar_ensure: 'present',
        jar_name: 'sample2.jar',
        jar_source: '/tmp/sample.jar',
        allow_insecure: true,
      }
    end

    it {
      is_expected.to contain_archive('tomcat::jar sample.jar').with(
        'source'         => '/tmp/sample.jar',
        'path'           => '/opt/apache-tomcat/test/lib2/sample2.jar',
        'allow_insecure' => true,
      )
    }
    it {
      is_expected.to contain_file('tomcat::jar sample.jar').with(
        'ensure' => 'file', 'path' => '/opt/apache-tomcat/test/lib2/sample2.jar',
        'owner' => 'tomcat', 'group' => 'tomcat', 'mode' => '0640'
      ).that_subscribes_to('Archive[tomcat::jar sample.jar]')
    }
  end
  context 'set deployment_path' do
    let :params do
      {
        deployment_path: '/opt/apache-tomcat/lib3',
        jar_source: '/tmp/sample.jar',
      }
    end

    it {
      is_expected.to contain_archive('tomcat::jar sample.jar').with(
        'source' => '/tmp/sample.jar',
        'path'   => '/opt/apache-tomcat/lib3/sample.jar',
      )
    }
    it {
      is_expected.to contain_file('tomcat::jar sample.jar').with(
        'ensure' => 'file', 'path' => '/opt/apache-tomcat/lib3/sample.jar',
        'owner' => 'tomcat', 'group' => 'tomcat', 'mode' => '0640'
      ).that_subscribes_to('Archive[tomcat::jar sample.jar]')
    }
  end
  context 'jar_purge is false' do
    let :params do
      {
        jar_ensure: 'absent',
        jar_purge: false,
      }
    end

    it {
      is_expected.to contain_file('/opt/apache-tomcat/lib/sample.jar').with(
        'ensure' => 'absent',
        'force'  => 'false',
      )
    }
    it {
      is_expected.not_to contain_file('/opt/apache-tomcat/lib/sample').with(
        'ensure' => 'absent',
        'force'  => 'true',
      )
    }
  end
  describe 'failing tests' do
    context 'bad jar name' do
      let :params do
        {
          jar_name: 'foo',
          jar_source: '/tmp/sample.jar',
        }
      end

      it do
        expect {
          catalogue
        }.to raise_error(Puppet::Error, %r{jar_name})
      end
    end
    context 'bad ensure' do
      let :params do
        {
          jar_ensure: 'foo',
          jar_source: '/tmp/sample.jar',
        }
      end

      it do
        expect {
          catalogue
        }.to raise_error(Puppet::Error, %r{(String|foo)})
      end
    end
    context 'bad purge' do
      let :params do
        {
          jar_ensure: 'absent',
          jar_purge: 'foo',
        }
      end

      it do
        expect {
          catalogue
        }.to raise_error(Puppet::Error, %r{Boolean})
      end
    end
    context 'invalid source' do
      let :params do
        {
          jar_source: 'foo',
        }
      end

      it do
        expect {
          catalogue.to_ral
        }.to raise_error(Puppet::Error, %r{invalid source url})
      end
    end
    context 'no source' do
      it do
        expect {
          catalogue
        }.to raise_error(Puppet::Error, %r{\$jar_source must be specified})
      end
    end
    context 'both jar_base and deployment_path' do
      let :params do
        {
          jar_source: '/tmp/sample.jar',
          jar_base: 'lib2',
          deployment_path: '/opt/apache-tomcat/lib3',
        }
      end

      it do
        expect {
          catalogue
        }.to raise_error(Puppet::Error, %r{Only one of \$jar_base and \$deployment_path can be specified})
      end
    end
    context 'set owner/group to war file' do
      let :params do
        {
          catalina_base: '/opt/apache-tomcat',
          jar_base: 'lib2',
          jar_ensure: 'present',
          jar_name: 'sample2.jar',
          jar_source: '/tmp/sample.jar',
          allow_insecure: true,
          user: 'tomcat2',
          group: 'tomcat2',
        }
      end

      it {
        is_expected.to contain_archive('tomcat::jar sample.jar').with(
          'source'         => '/tmp/sample.jar',
          'path'           => '/opt/apache-tomcat/lib2/sample2.jar',
          'allow_insecure' => true,
        )
      }
      it {
        is_expected.to contain_file('tomcat::jar sample.jar').with(
          'ensure' => 'file', 'path' => '/opt/apache-tomcat/lib2/sample2.jar',
          'owner' => 'tomcat2', 'group' => 'tomcat2', 'mode' => '0640'
        ).that_subscribes_to('Archive[tomcat::jar sample.jar]')
      }
    end
  end
end
