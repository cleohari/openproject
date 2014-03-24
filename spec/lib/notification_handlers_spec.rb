require File.expand_path('../../spec_helper', __FILE__)

describe OpenProject::GithubIntegration do
  before do
    Setting.stub(:host_name).and_return('example.net')
  end

  describe '.extract_work_package_ids' do
    it 'should return an empty array for an empty source' do
      result = OpenProject::GithubIntegration::NotificationHandlers.send(
                :extract_work_package_ids, '')
      expect(result).to eql([])
    end

    it 'should find a plain work package url' do
      source = 'Blabla\nhttps://example.net/work_packages/234\n'
      result = OpenProject::GithubIntegration::NotificationHandlers.send(
                :extract_work_package_ids, source)
      expect(result).to eql([234])
    end

    it 'should find a work package url in markdown link syntax' do
      source = 'Blabla\n[WP 234](https://example.net/work_packages/234)\n'
      result = OpenProject::GithubIntegration::NotificationHandlers.send(
                :extract_work_package_ids, source)
      expect(result).to eql([234])
    end

    it 'should find multiple work package urls' do
      source = "I reference https://example.net/work_packages/434\n and Blabla\n[WP 234](https://example.net/wp/234)\n"
      result = OpenProject::GithubIntegration::NotificationHandlers.send(
                :extract_work_package_ids, source)
      expect(result).to eql([434, 234])
    end
  end

  describe '.find_visible_work_packages' do
    let(:user) { 'A User' }
    let(:visible_wp) do
      wp = double('Visible Work Package')
      wp.should_receive(:visible?).at_least(:once).and_return(true)
      wp
    end
    let(:invisible_wp) do
      wp = double('Invisible Work Package')
      wp.should_receive(:visible?).at_least(:once).and_return(false)
      wp
    end

    before do
      WorkPackage.stub(:includes).and_return(WorkPackage)
      WorkPackage.stub(:find_by_id) {|id| wps[id]}
    end

    shared_examples_for 'GithubIntegration.find_visible_work_packages' do
      subject { OpenProject::GithubIntegration::NotificationHandlers.send(
                  :find_visible_work_packages, ids, user) }
      it { expect(subject).to eql(expected) }
    end

    describe 'should find an existing work package' do
      let(:wps) { [visible_wp] }
      let(:ids)  { [0] }
      let(:expected) { wps }

      it_behaves_like 'GithubIntegration.find_visible_work_packages'
    end

    describe 'should not find a non-existing work package' do
      let(:wps) { [invisible_wp] }
      let(:ids)  { [0] }
      let(:expected) { [] }

      it_behaves_like 'GithubIntegration.find_visible_work_packages'
    end

    describe 'should find multiple existing work packages' do
      let(:wps) { [visible_wp, visible_wp] }
      let(:ids)  { [0, 1] }
      let(:expected) { wps }

      it_behaves_like 'GithubIntegration.find_visible_work_packages'
    end

    describe 'should not find work package which the user shall not see' do
      let(:wps) { [visible_wp, invisible_wp, visible_wp, invisible_wp] }
      let(:ids)  { [0, 1, 2, 3] }
      let(:expected) { [visible_wp, visible_wp] }

      it_behaves_like 'GithubIntegration.find_visible_work_packages'
    end
  end

  describe '.pull_request' do
    OpenProject::GithubIntegration::NotificationHandlers.pull_request(1)
  end
end
