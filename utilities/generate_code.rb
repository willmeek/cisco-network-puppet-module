require 'json'
require 'date'
puts 'creating demo manifest file'
json = File.read('input.json')
obj = JSON.parse(json)
name = obj['Name']
dir = Dir.pwd + '/../'
fname = dir + 'examples/cisco/demo_' + name + '.pp'
file = File.open(fname, 'w')
month = Date::MONTHNAMES[Date.today.month]
year = Date.today.year.to_s
bprops = obj['Bool_Properties']
nbprops = obj['Non_Bool_Properties']
props = []
props << bprops << nbprops
props.flatten!
cap = name.slice(0, 1).capitalize + name.slice(1..-1)
file.puts '# Manifest to demo cisco_' + name + ' provider
#
# Copyright (c) ' + year + ' Cisco and/or its affiliates.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.'
file.puts "\nclass ciscopuppet::cisco::demo_" + name + ' {'
file.puts '  cisco_' + name + " { '__put_provider_name_here__':"
file.puts '    ensure   => present,'
props.each do |prop|
  file.puts '    ' + prop + '   => __put_prop_value_here__,'
end
file.puts "  }
}"
file.close
puts 'creating type file'
fname = dir + 'lib/puppet/type/cisco_' + name + '.rb'
file = File.open(fname, 'w')
file.puts '# Manages the Cisco ' + cap + ' configuration resource.
#
# ' + month + ' ' + year + '
#
# Copyright (c) ' + year + ' Cisco and/or its affiliates.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.'
file.puts "\n"
file.puts 'Puppet::Type.newtype(:cisco_' + name + ') do
  @doc = "Manages a cisco ' + name + '

    cisco_' + name + ' {__put_provider_name_here__:
      ..attributes..
    }'
file.puts "\n"
file.puts "Examples:
    cisco_" + name + "{'__put_provider_name_here__':
      ensure  => 'present',"
props.each do |prop|
  file.puts '      ' + prop + '   => __put_prop_value_here__,'
end
file.puts '    }
  "'
file.puts "\n  ensurable"
file.puts "\n  ###################
  # Resource Naming #
  ###################

  # Parse out the title to fill in the attributes in these
  # patterns. These attributes can be overwritten later.
  def self.title_patterns
  end\n"
file.puts "\n  # Overwrites name method. Original method simply returns self[:name],
  # which is no longer valid or complete.
  # Would not have failed, but just return nothing useful.
  def name
  end"
file.puts '  ##############
  # Attributes #
  ##############'
bprops.each do |prop|
  file.puts "\n  newproperty(:" + prop + ") do
    desc '__put_description_here'
    newvalues(:true, :false, :default)
  end # property " + prop
end
nbprops.each do |prop|
  file.puts "\n  newproperty(:" + prop + ") do
    desc '__put_description_here'
  end # property " + prop
end
file.puts 'end'
file.close
puts 'creating provider file'
dir = Dir.pwd + '/../lib/puppet/provider/cisco_' + name
Dir.mkdir(dir) unless File.exist?(dir)
dir = Dir.pwd + '/../'
fname = dir + 'lib/puppet/provider/cisco_' + name + '/cisco.rb'
file = File.open(fname, 'w')
file.puts '# ' + month + ', ' + year + '
#
# Copyright (c) ' + year + ' Cisco and/or its affiliates.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.'

file.puts "require 'cisco_node_utils' if Puppet.features.cisco_node_utils?
begin
  require 'puppet_x/cisco/autogen'
rescue LoadError # seen on master, not on agent
  # See longstanding Puppet issues #4248, #7316, #14073, #14149, etc. Ugh.
  require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..',
                                     'puppet_x', 'cisco', 'autogen.rb'))
end"
file.puts 'Puppet::Type.type(:cisco_' + name + ").provide(:cisco) do
  desc 'The Cisco " + name + " provider.'

  confine feature: :cisco_node_utils
  defaultfor operatingsystem: :nexus

  mk_resource_methods"
upper = name.upcase
file.puts "\n" + '  ' + upper + '_NON_BOOL_PROPS = ['
nbprops.each do |prop|
  file.puts '    :' + prop + ','
end
file.puts '  ]'
file.puts "\n" + '  ' + upper + '_BOOL_PROPS = ['
bprops.each do |prop|
  file.puts '    :' + prop + ','
end
file.puts '  ]'

file.puts "\n  " + upper + '_ALL_PROPS = ' + upper + '_NON_BOOL_PROPS + ' + upper + '_BOOL_PROPS'
file.puts "  PuppetX::Cisco::AutoGen.mk_puppet_methods(:non_bool, self, '@nu',
                                            " + upper + '_NON_BOOL_PROPS)'
file.puts "  PuppetX::Cisco::AutoGen.mk_puppet_methods(:bool, self, '@nu',
                                            " + upper + '_BOOL_PROPS)'
file.puts "\n  def initialize(value={})
    super(value)
    @property_flush = {}
  end"
file.puts "\n  def self.properties_get()
    current_state = {
      ensure: :present,
    }

    # Call node_utils getter for each property
    " + upper + "_NON_BOOL_PROPS.each do |prop|
      current_state[prop] = nu_obj.send(prop)
    end"
file.puts "\n    " + upper + "_BOOL_PROPS.each do |prop|
      val = nu_obj.send(prop)
      if val.nil?
        current_state[prop] = nil
      else
        current_state[prop] = val ? :true : :false
      end
    end
    new(current_state)
  end # self.properties_get"
file.puts "\n  def self.instances
  end # self.instances"
file.puts "\n  def self.prefetch(resources)
  end"
file.puts "\n  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    @property_flush[:ensure] = :present
  end

  def destroy
    @property_flush[:ensure] = :absent
  end"
file.puts "\n  def instance_name
    name
  end"
file.puts "\n  def properties_set(new_obj=false)
    " + upper + "_ALL_PROPS.each do |prop|
      next unless @resource[prop]"
file.puts '      send("#{prop}=", @resource[prop]) if new_obj
      unless @property_flush[prop].nil?
        @nu.send("#{prop}=", @property_flush[prop]) if
          @nu.respond_to?("#{prop}=")
      end
    end
  end'
file.puts "\n  def flush
    if @property_flush[:ensure] == :absent
      @nu.destroy
      @nu = nil
    else
      # Create/Update
      new_obj = false
      if @nu.nil?
        new_obj = true
      end
      properties_set(new_obj)
    end
  end
end"
file.close
puts 'creating beaker file'
dir = Dir.pwd + '/../tests/beaker_tests/cisco_' + name
Dir.mkdir(dir) unless File.exist?(dir)
dir = Dir.pwd + '/../'
fname = dir + 'tests/beaker_tests/cisco_' + name + '/test_' + name + '.rb'
file = File.open(fname, 'w')
file.puts '###############################################################################
# Copyright (c) ' + year + ' Cisco and/or its affiliates.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
###############################################################################
#
# See README-develop-beaker-scripts.md (Section: Test Script Variable Reference)
# for information regarding:
#  - test script general prequisites
#  - command return codes
#  - A description of the ' + "'tests'" + ' hash and its usage
#
###############################################################################'
file.puts "require File.expand_path('../../lib/utilitylib.rb', __FILE__)"
file.puts "\n # Test hash top-level keys
tests = {
  master:           master,
  agent:            agent,
  operating_system: 'nexus',
  resource_name:    'cisco_" + name + "',
}

skip_unless_supported(tests)

# Test hash test cases
tests[:default] = {
  desc:           '1.1 Default Properties',
  title_pattern:  '__put_name_here__',
  manifest_props: {"
props.each do |prop|
  file.puts '    ' + prop + ":                           'default',"
end
file.puts "  },
  code:           [0, 2],
  resource:       {"
props.each do |prop|
  file.puts '    ' + prop + ":                           '__put_default_value_here__',"
end
file.puts "  },
}"
file.puts "\ntests[:non_default] = {
  desc:           '2.1 Non Defaults',
  title_pattern:  'default',
  manifest_props: {"
props.each do |prop|
  file.puts '    ' + prop + ":                           '__put_set_value_here__',"
end
file.puts "  },
}"
file.puts "def cleanup(agent)
end

#################################################################
# TEST CASE EXECUTION
#################################################################
test_name " + '"TestCase :: #{tests[:resource_name]}" do
  teardown { cleanup(agent) }
  cleanup(agent)

  # -------------------------------------------------------------------
  logger.info("\n#{' + "'-'" + ' * 60}\nSection 1. Default Property Testing")
  test_harness_run(tests, :default)

  # -------------------------------------------------------------------
  logger.info("\n#{' + "'-'" + ' * 60}\nSection 2. Non Default Property Testing")

  cleanup(agent)
  test_harness_run(tests, :non_default)

  # -------------------------------------------------------------------
  skipped_tests_summary(tests)
end

logger.info("TestCase :: #{tests[:resource_name]} :: End")'
file.close
