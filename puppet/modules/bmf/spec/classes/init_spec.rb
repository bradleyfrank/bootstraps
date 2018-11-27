require 'spec_helper'
describe 'bmf' do
  context 'with default values for all parameters' do
    it { should contain_class('bmf') }
  end
end
