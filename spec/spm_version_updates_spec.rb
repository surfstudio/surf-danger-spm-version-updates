# frozen_string_literal: true

require File.expand_path("spec_helper", __dir__)

module Danger
  describe Danger::DangerSpmVersionUpdates do
    it "is a plugin" do
      expect(described_class.new(nil)).to be_a Danger::Plugin
    end

    describe "with Dangerfile" do
      before do
        @dangerfile = testing_dangerfile
        @my_plugin = @dangerfile.spm_version_updates

        # mock the PR data
        # you can then use this, eg. github.pr_author, later in the spec
        json = File.read("#{File.dirname(__FILE__)}/support/fixtures/github_pr.json") # example json: `curl https://api.github.com/repos/danger/danger-plugin-template/pulls/18 > github_pr.json`
        allow(@my_plugin.github).to receive(:pr_json).and_return(json)
      end

      it "(project) Does not report pre-release versions by default" do
        allow(@my_plugin).to receive(:git_versions)
          .and_return [
            Semantic::Version.new("12.1.6"),
            Semantic::Version.new("12.2.0-beta.1"),
            Semantic::Version.new("12.2.0-beta.2"),
          ].sort.reverse
        allow(@my_plugin).to receive(:get_local_packages)
          .and_return []

        @my_plugin.check_when_exact = true
        @my_plugin.check_for_updates(
          "#{File.dirname(__FILE__)}/support/fixtures/project-ExactVersion.xcodeproj",
          "#{File.dirname(__FILE__)}/support/fixtures/project-ExactVersion.xcodeproj"
        )
        expect(@dangerfile.status_report[:warnings]).to eq([])
      end

      it "(project) Does report new versions for exact versions when configured" do
        allow(@my_plugin).to receive(:git_versions)
          .and_return [
            Semantic::Version.new("12.1.6"),
            Semantic::Version.new("12.1.7"),
          ].sort.reverse
        allow(@my_plugin).to receive(:get_local_packages)
          .and_return []

        @my_plugin.check_when_exact = true
        @my_plugin.check_for_updates(
          "#{File.dirname(__FILE__)}/support/fixtures/project-ExactVersion.xcodeproj",
          "#{File.dirname(__FILE__)}/support/fixtures/project-ExactVersion.xcodeproj"
        )

        expect(@dangerfile.status_report[:warnings]).to eq(
          [
            "Newer version of (project) kean/Nuke: 12.1.7 (but this package is set to exact version 12.1.6)\n",
          ]
        )
      end

      it "(project) Does report pre-release versions for exact versions when configured" do
        allow(@my_plugin).to receive(:git_versions)
          .and_return [
            Semantic::Version.new("12.1.6"),
            Semantic::Version.new("12.2.0-beta.2"),
          ].sort.reverse
        allow(@my_plugin).to receive(:get_local_packages)
          .and_return []

        @my_plugin.check_when_exact = true
        @my_plugin.report_pre_releases = true
        @my_plugin.check_for_updates(
          "#{File.dirname(__FILE__)}/support/fixtures/project-ExactVersion.xcodeproj",
          "#{File.dirname(__FILE__)}/support/fixtures/project-ExactVersion.xcodeproj"
        )

        expect(@dangerfile.status_report[:warnings]).to eq(
          [
            "Newer version of (project) kean/Nuke: 12.2.0-beta.2 (but this package is set to exact version 12.1.6)\n",
          ]
        )
      end

      it "(project) Does report new versions for up to next major" do
        allow(@my_plugin).to receive(:git_versions)
          .and_return [
            Semantic::Version.new("12.1.6"),
            Semantic::Version.new("12.1.7"),
          ].sort.reverse
        allow(@my_plugin).to receive(:get_local_packages)
          .and_return []

        @my_plugin.check_for_updates(
          "#{File.dirname(__FILE__)}/support/fixtures/project-UpToNextMajor.xcodeproj",
          "#{File.dirname(__FILE__)}/support/fixtures/project-UpToNextMajor.xcodeproj"
        )

        expect(@dangerfile.status_report[:warnings]).to eq(
          [
            "Newer version of (project) kean/Nuke: 12.1.7",
          ]
        )
      end

      it "(project) Reports pre-release versions for up to next major when configured" do
        allow(@my_plugin).to receive(:git_versions)
          .and_return [
            Semantic::Version.new("12.1.6"),
            Semantic::Version.new("12.2.0-beta.2"),
          ].sort.reverse
        allow(@my_plugin).to receive(:get_local_packages)
          .and_return []

        @my_plugin.check_when_exact = true
        @my_plugin.report_pre_releases = true
        @my_plugin.check_for_updates(
          "#{File.dirname(__FILE__)}/support/fixtures/project-UpToNextMajor.xcodeproj",
          "#{File.dirname(__FILE__)}/support/fixtures/project-UpToNextMajor.xcodeproj"
        )

        expect(@dangerfile.status_report[:warnings]).to eq(
          [
            "Newer version of (project) kean/Nuke: 12.2.0-beta.2",
          ]
        )
      end

      it "(project) Does not report pre-release versions for up to next major" do
        allow(@my_plugin).to receive(:git_versions)
          .and_return [
            Semantic::Version.new("12.1.6"),
            Semantic::Version.new("12.2.0-beta.2"),
            Semantic::Version.new("13.0.0"),
          ].sort.reverse
        allow(@my_plugin).to receive(:get_local_packages)
          .and_return []

        @my_plugin.check_for_updates(
          "#{File.dirname(__FILE__)}/support/fixtures/project-UpToNextMajor.xcodeproj",
          "#{File.dirname(__FILE__)}/support/fixtures/project-UpToNextMajor.xcodeproj"
        )

        expect(@dangerfile.status_report[:warnings]).to eq([])
      end

      it "(project) Does not report new versions for up to next major when next version is major" do
        allow(@my_plugin).to receive(:git_versions)
          .and_return [
            Semantic::Version.new("12.1.6"),
            Semantic::Version.new("13.0.0"),
          ].sort.reverse
        allow(@my_plugin).to receive(:get_local_packages)
          .and_return []

        @my_plugin.check_for_updates(
          "#{File.dirname(__FILE__)}/support/fixtures/project-UpToNextMajor.xcodeproj",
          "#{File.dirname(__FILE__)}/support/fixtures/project-UpToNextMajor.xcodeproj"
        )

        expect(@dangerfile.status_report[:warnings]).to eq([])
      end

      it "(project) Does report new versions for up to next major when next version is major and configured" do
        allow(@my_plugin).to receive(:git_versions)
          .and_return [
            Semantic::Version.new("12.1.6"),
            Semantic::Version.new("13.0.0"),
          ].sort.reverse
        allow(@my_plugin).to receive(:get_local_packages)
          .and_return []

        @my_plugin.report_above_maximum = true
        @my_plugin.check_for_updates(
          "#{File.dirname(__FILE__)}/support/fixtures/project-UpToNextMajor.xcodeproj",
          "#{File.dirname(__FILE__)}/support/fixtures/project-UpToNextMajor.xcodeproj"
        )

        expect(@dangerfile.status_report[:warnings]).to eq(["Newest version of (project) kean/Nuke: 13.0.0 (but this package is configured up to the next major version)\n"])
      end

      it "(local) Does report for revision when configured: bad input and new version" do
        allow(@my_plugin).to receive(:filter_remote_packages)
          .and_return []
        allow(@my_plugin).to receive(:git_versions)
          .and_return [
            Semantic::Version.new("4.0.0"),
            Semantic::Version.new("13.0.0-beta.1"),
          ].sort.reverse

        @my_plugin.check_when_exact = true
        @my_plugin.check_for_updates(
          "#{File.dirname(__FILE__)}/support/fixtures/local-Revision.xcodeproj",
          "#{File.dirname(__FILE__)}/support/fixtures/local-Revision.xcodeproj"
        )

        expect(@dangerfile.status_report[:warnings]).to eq([
          "Newer version of (local) surfstudio/NodeKit: 4.0.0 (but this package is set to exact version 3.5.0)\n",
          "(local) surfstudio/ReactiveDataDisplayManager: non-version values in revision are not analyzed: 58964e455b9f149ae63e123f3c1f62a0c0bf13c8"
        ])
      end

      it "(local) Does not report for revision and report bad input" do
        allow(@my_plugin).to receive(:filter_remote_packages)
          .and_return []
        allow(@my_plugin).to receive(:git_versions)
          .and_return [
            Semantic::Version.new("2.0.0"),
            Semantic::Version.new("3.5.0"),
            Semantic::Version.new("13.0.0-beta.1"),
          ].sort.reverse

        @my_plugin.check_when_exact = true
        @my_plugin.check_for_updates(
          "#{File.dirname(__FILE__)}/support/fixtures/local-Revision.xcodeproj",
          "#{File.dirname(__FILE__)}/support/fixtures/local-Revision.xcodeproj"
        )

        expect(@dangerfile.status_report[:warnings]).to eq([
          "(local) surfstudio/ReactiveDataDisplayManager: non-version values in revision are not analyzed: 58964e455b9f149ae63e123f3c1f62a0c0bf13c8"
        ])
      end

      it "(local) Does report for revision when not configured: bad input" do
        allow(@my_plugin).to receive(:filter_remote_packages)
          .and_return []
        allow(@my_plugin).to receive(:git_versions)
          .and_return [
            Semantic::Version.new("4.0.0"),
            Semantic::Version.new("13.0.0-beta.1"),
          ].sort.reverse

        @my_plugin.check_for_updates(
          "#{File.dirname(__FILE__)}/support/fixtures/local-Revision.xcodeproj",
          "#{File.dirname(__FILE__)}/support/fixtures/local-Revision.xcodeproj"
        )

        expect(@dangerfile.status_report[:warnings]).to eq([
          "(local) surfstudio/ReactiveDataDisplayManager: non-version values in revision are not analyzed: 58964e455b9f149ae63e123f3c1f62a0c0bf13c8"
        ])
      end

      it "(local) Does report pre-release for revision when configured: bad input and new version" do
        allow(@my_plugin).to receive(:filter_remote_packages)
          .and_return []
        allow(@my_plugin).to receive(:git_versions)
          .and_return [
            Semantic::Version.new("4.0.0"),
            Semantic::Version.new("13.0.0-beta.1"),
          ].sort.reverse

        @my_plugin.report_pre_releases = true
        @my_plugin.check_when_exact = true
        @my_plugin.check_for_updates(
          "#{File.dirname(__FILE__)}/support/fixtures/local-Revision.xcodeproj",
          "#{File.dirname(__FILE__)}/support/fixtures/local-Revision.xcodeproj"
        )

        expect(@dangerfile.status_report[:warnings]).to eq([
          "Newer version of (local) surfstudio/NodeKit: 13.0.0-beta.1 (but this package is set to exact version 3.5.0)\n",
          "(local) surfstudio/ReactiveDataDisplayManager: non-version values in revision are not analyzed: 58964e455b9f149ae63e123f3c1f62a0c0bf13c8"
        ])
      end

      it "(local) Does not report new versions for exact" do
        allow(@my_plugin).to receive(:filter_remote_packages)
          .and_return []
        allow(@my_plugin).to receive(:git_versions)
          .and_return [
            Semantic::Version.new("3.5.0"),
            Semantic::Version.new("3.2.0"),
            Semantic::Version.new("13.0.0-beta.1"),
          ].sort.reverse

        @my_plugin.check_when_exact = true
        @my_plugin.check_for_updates(
          "#{File.dirname(__FILE__)}/support/fixtures/local-Exact.xcodeproj",
          "#{File.dirname(__FILE__)}/support/fixtures/local-Exact.xcodeproj"
        )

        expect(@dangerfile.status_report[:warnings]).to eq([])
      end

      it "(local) Does report new versions for exact when configured" do
        allow(@my_plugin).to receive(:filter_remote_packages)
          .and_return []
        allow(@my_plugin).to receive(:git_versions)
          .and_return [
            Semantic::Version.new("4.0.0"),
            Semantic::Version.new("13.0.0-beta.1"),
          ].sort.reverse

        @my_plugin.check_when_exact = true
        @my_plugin.check_for_updates(
          "#{File.dirname(__FILE__)}/support/fixtures/local-Exact.xcodeproj",
          "#{File.dirname(__FILE__)}/support/fixtures/local-Exact.xcodeproj"
        )

        expect(@dangerfile.status_report[:warnings]).to eq([
          "Newer version of (local) surfstudio/NodeKit: 4.0.0 (but this package is set to exact version 3.5.0)\n",
        ])
      end

      it "(local) Does not report new versions for exact" do
        allow(@my_plugin).to receive(:filter_remote_packages)
          .and_return []
        allow(@my_plugin).to receive(:git_versions)
          .and_return [
            Semantic::Version.new("4.0.0"),
            Semantic::Version.new("13.0.0-beta.1"),
          ].sort.reverse

        @my_plugin.check_for_updates(
          "#{File.dirname(__FILE__)}/support/fixtures/local-Exact.xcodeproj",
          "#{File.dirname(__FILE__)}/support/fixtures/local-Exact.xcodeproj"
        )

        expect(@dangerfile.status_report[:warnings]).to eq([])
      end

      it "(local) Does report pre-release versions for exact when configured" do
        allow(@my_plugin).to receive(:filter_remote_packages)
          .and_return []
        allow(@my_plugin).to receive(:git_versions)
          .and_return [
            Semantic::Version.new("4.0.0"),
            Semantic::Version.new("13.0.0-beta.1"),
          ].sort.reverse

        @my_plugin.check_when_exact = true
        @my_plugin.report_pre_releases = true
        @my_plugin.check_for_updates(
          "#{File.dirname(__FILE__)}/support/fixtures/local-Exact.xcodeproj",
          "#{File.dirname(__FILE__)}/support/fixtures/local-Exact.xcodeproj"
        )

        expect(@dangerfile.status_report[:warnings]).to eq([
          "Newer version of (local) surfstudio/NodeKit: 13.0.0-beta.1 (but this package is set to exact version 3.5.0)\n"
        ])
      end

      it "(local) Does report new commit for branch when configured" do
        allow(@my_plugin).to receive(:filter_remote_packages)
          .and_return []
        allow(@my_plugin).to receive(:git_branch_last_commit)
          .and_return "NEWER_COMMIT_HASH"

        @my_plugin.check_when_exact = true
        @my_plugin.check_for_updates(
          "#{File.dirname(__FILE__)}/support/fixtures/local-Branch.xcodeproj",
          "#{File.dirname(__FILE__)}/support/fixtures/local-Branch.xcodeproj"
        )

        expect(@dangerfile.status_report[:warnings]).to eq([
          "Newer commit available for (local) surfstudio/NodeKit: NEWER_COMMIT_HASH"
        ])
      end

      it "(local) Does not report new commit for branch" do
        allow(@my_plugin).to receive(:filter_remote_packages)
          .and_return []
        allow(@my_plugin).to receive(:git_branch_last_commit)
          .and_return "NEWER_COMMIT_HASH"

        @my_plugin.check_for_updates(
          "#{File.dirname(__FILE__)}/support/fixtures/local-Branch.xcodeproj",
          "#{File.dirname(__FILE__)}/support/fixtures/local-Branch.xcodeproj"
        )

        expect(@dangerfile.status_report[:warnings]).to eq([])
      end

      it "(local) Does not report for branch" do
        allow(@my_plugin).to receive(:filter_remote_packages)
          .and_return []
        allow(@my_plugin).to receive(:git_branch_last_commit)
          .and_return "abfb06df71c287873dd96d478ef5ce185c54414b"

        @my_plugin.check_for_updates(
          "#{File.dirname(__FILE__)}/support/fixtures/local-Branch.xcodeproj",
          "#{File.dirname(__FILE__)}/support/fixtures/local-Branch.xcodeproj"
        )

        expect(@dangerfile.status_report[:warnings]).to eq([])
      end

      it "(local) Does report new versions for up to next major" do
        allow(@my_plugin).to receive(:filter_remote_packages)
          .and_return []
        allow(@my_plugin).to receive(:git_versions)
          .and_return [
            Semantic::Version.new("3.9.0"),
            Semantic::Version.new("13.0.0-beta.1"),
          ].sort.reverse

        @my_plugin.check_for_updates(
          "#{File.dirname(__FILE__)}/support/fixtures/local-UpToNextMajor.xcodeproj",
          "#{File.dirname(__FILE__)}/support/fixtures/local-UpToNextMajor.xcodeproj"
        )

        expect(@dangerfile.status_report[:warnings]).to eq([
          "Newer version of (local) surfstudio/NodeKit: 3.9.0"
        ])
      end

      it "(local) Does report new versions for up to next major when next version is major and configured" do
        allow(@my_plugin).to receive(:filter_remote_packages)
          .and_return []
        allow(@my_plugin).to receive(:git_versions)
          .and_return [
            Semantic::Version.new("3.9.0"),
            Semantic::Version.new("4.0.0"),
            Semantic::Version.new("13.0.0-beta.1"),
          ].sort.reverse

        @my_plugin.report_above_maximum = true
        @my_plugin.check_for_updates(
          "#{File.dirname(__FILE__)}/support/fixtures/local-UpToNextMajor.xcodeproj",
          "#{File.dirname(__FILE__)}/support/fixtures/local-UpToNextMajor.xcodeproj"
        )

        expect(@dangerfile.status_report[:warnings]).to eq([
          "Newer version of (local) surfstudio/NodeKit: 3.9.0",
          "Newest version of (local) surfstudio/NodeKit: 4.0.0 (but this package is configured up to the next major version)\n"
        ])
      end

      it "(local) Does not report for up to next major" do
        allow(@my_plugin).to receive(:filter_remote_packages)
          .and_return []
        allow(@my_plugin).to receive(:git_versions)
          .and_return [
            Semantic::Version.new("3.2.0"),
            Semantic::Version.new("3.5.0"),
            Semantic::Version.new("13.0.0-beta.1"),
          ].sort.reverse

        @my_plugin.report_above_maximum = true
        @my_plugin.check_for_updates(
          "#{File.dirname(__FILE__)}/support/fixtures/local-UpToNextMajor.xcodeproj",
          "#{File.dirname(__FILE__)}/support/fixtures/local-UpToNextMajor.xcodeproj"
        )

        expect(@dangerfile.status_report[:warnings]).to eq([])
      end

      it "(local) Does report new versions for up to next major when next version is major" do
        allow(@my_plugin).to receive(:filter_remote_packages)
          .and_return []
        allow(@my_plugin).to receive(:git_versions)
          .and_return [
            Semantic::Version.new("3.9.0"),
            Semantic::Version.new("4.0.0"),
            Semantic::Version.new("13.0.0-beta.1"),
          ].sort.reverse

        @my_plugin.check_for_updates(
          "#{File.dirname(__FILE__)}/support/fixtures/local-UpToNextMajor.xcodeproj",
          "#{File.dirname(__FILE__)}/support/fixtures/local-UpToNextMajor.xcodeproj"
        )

        expect(@dangerfile.status_report[:warnings]).to eq([
          "Newer version of (local) surfstudio/NodeKit: 3.9.0",
        ])
      end

      it "(local) Does report pre-release versions for up to next major when next version is major and configured" do
        allow(@my_plugin).to receive(:filter_remote_packages)
          .and_return []
        allow(@my_plugin).to receive(:git_versions)
          .and_return [
            Semantic::Version.new("3.9.0"),
            Semantic::Version.new("4.0.0"),
            Semantic::Version.new("13.0.0-beta.1"),
          ].sort.reverse

        @my_plugin.report_above_maximum = true
        @my_plugin.report_pre_releases = true
        @my_plugin.check_for_updates(
          "#{File.dirname(__FILE__)}/support/fixtures/local-UpToNextMajor.xcodeproj",
          "#{File.dirname(__FILE__)}/support/fixtures/local-UpToNextMajor.xcodeproj"
        )

        expect(@dangerfile.status_report[:warnings]).to eq([
          "Newer version of (local) surfstudio/NodeKit: 3.9.0",
          "Newest version of (local) surfstudio/NodeKit: 13.0.0-beta.1 (but this package is configured up to the next major version)\n"
        ])
      end

      it "(local) Does report pre-release versions for up to next major when and configured" do
        allow(@my_plugin).to receive(:filter_remote_packages)
          .and_return []
        allow(@my_plugin).to receive(:git_versions)
          .and_return [
            Semantic::Version.new("3.7.0"),
            Semantic::Version.new("3.8.0-beta.1"),
          ].sort.reverse

        @my_plugin.report_pre_releases = true
        @my_plugin.check_for_updates(
          "#{File.dirname(__FILE__)}/support/fixtures/local-UpToNextMajor.xcodeproj",
          "#{File.dirname(__FILE__)}/support/fixtures/local-UpToNextMajor.xcodeproj"
        )

        expect(@dangerfile.status_report[:warnings]).to eq([
          "Newer version of (local) surfstudio/NodeKit: 3.8.0-beta.1",
        ])
      end

      it "(local) Does not report pre-release versions for up to next major" do
        allow(@my_plugin).to receive(:filter_remote_packages)
          .and_return []
        allow(@my_plugin).to receive(:git_versions)
          .and_return [
            Semantic::Version.new("3.7.0"),
            Semantic::Version.new("3.8.0-beta.1"),
          ].sort.reverse

        @my_plugin.check_for_updates(
          "#{File.dirname(__FILE__)}/support/fixtures/local-UpToNextMajor.xcodeproj",
          "#{File.dirname(__FILE__)}/support/fixtures/local-UpToNextMajor.xcodeproj"
        )

        expect(@dangerfile.status_report[:warnings]).to eq([
          "Newer version of (local) surfstudio/NodeKit: 3.7.0",
        ])
      end

      it "(local) Does report new versions for range" do
        allow(@my_plugin).to receive(:filter_remote_packages)
          .and_return []
        allow(@my_plugin).to receive(:git_versions)
          .and_return [
            Semantic::Version.new("3.7.0"),
            Semantic::Version.new("3.3.3"),
            Semantic::Version.new("3.8.0-beta.1"),
          ].sort.reverse

        @my_plugin.check_for_updates(
          "#{File.dirname(__FILE__)}/support/fixtures/local-Range.xcodeproj",
          "#{File.dirname(__FILE__)}/support/fixtures/local-Range.xcodeproj"
        )

        expect(@dangerfile.status_report[:warnings]).to eq([
          "Newer version of (local) surfstudio/NodeKit: 3.3.3 ",
        ])
      end

      it "(local) Does report pre-release versions for range when configured" do
        allow(@my_plugin).to receive(:filter_remote_packages)
          .and_return []
        allow(@my_plugin).to receive(:git_versions)
          .and_return [
            Semantic::Version.new("3.7.0"),
            Semantic::Version.new("3.3.3"),
            Semantic::Version.new("3.3.8-beta.1"),
            Semantic::Version.new("3.8.0-beta.1"),
          ].sort.reverse

        @my_plugin.report_pre_releases = true
        @my_plugin.check_for_updates(
          "#{File.dirname(__FILE__)}/support/fixtures/local-Range.xcodeproj",
          "#{File.dirname(__FILE__)}/support/fixtures/local-Range.xcodeproj"
        )

        expect(@dangerfile.status_report[:warnings]).to eq([
          "Newer version of (local) surfstudio/NodeKit: 3.3.8-beta.1 ",
        ])
      end

      it "(local) Does report new versions for range when greater than max and configured" do
        allow(@my_plugin).to receive(:filter_remote_packages)
          .and_return []
        allow(@my_plugin).to receive(:git_versions)
          .and_return [
            Semantic::Version.new("3.7.0"),
            Semantic::Version.new("3.3.1"),
            Semantic::Version.new("3.8.0-beta.1"),
          ].sort.reverse

        @my_plugin.report_above_maximum = true
        @my_plugin.check_for_updates(
          "#{File.dirname(__FILE__)}/support/fixtures/local-Range.xcodeproj",
          "#{File.dirname(__FILE__)}/support/fixtures/local-Range.xcodeproj"
        )

        expect(@dangerfile.status_report[:warnings]).to eq([
          "Newest version of (local) surfstudio/NodeKit: 3.7.0 (but this package is configured up to the next 3.4.0 version)\n",
        ])
      end

      it "(local) Does not report for range" do
        allow(@my_plugin).to receive(:filter_remote_packages)
          .and_return []
        allow(@my_plugin).to receive(:git_versions)
          .and_return [
            Semantic::Version.new("3.2.0"),
            Semantic::Version.new("3.3.1"),
            Semantic::Version.new("3.8.0-beta.1"),
          ].sort.reverse

        @my_plugin.check_for_updates(
          "#{File.dirname(__FILE__)}/support/fixtures/local-Range.xcodeproj",
          "#{File.dirname(__FILE__)}/support/fixtures/local-Range.xcodeproj"
        )

        expect(@dangerfile.status_report[:warnings]).to eq([])
      end

      it "(local) Does report pre-release versions for range when greater than max and configured" do
        allow(@my_plugin).to receive(:filter_remote_packages)
          .and_return []
        allow(@my_plugin).to receive(:git_versions)
          .and_return [
            Semantic::Version.new("3.7.0"),
            Semantic::Version.new("3.3.5"),
            Semantic::Version.new("3.8.0-beta.1"),
          ].sort.reverse

        @my_plugin.report_above_maximum = true
        @my_plugin.report_pre_releases = true
        @my_plugin.check_for_updates(
          "#{File.dirname(__FILE__)}/support/fixtures/local-Range.xcodeproj",
          "#{File.dirname(__FILE__)}/support/fixtures/local-Range.xcodeproj"
        )

        expect(@dangerfile.status_report[:warnings]).to eq([
          "Newer version of (local) surfstudio/NodeKit: 3.3.5 ",
          "Newest version of (local) surfstudio/NodeKit: 3.8.0-beta.1 (but this package is configured up to the next 3.4.0 version)\n",
        ])
      end

      it "Parsing local manifests: branch" do
        expected_parsed = @my_plugin.get_local_packages("#{File.dirname(__FILE__)}/support/fixtures/local-parsing/Branch")
        branch_package = [
          "https://github.com/surfstudio/NodeKit.git",
          {
            "branch"=>"BRANCH",
            "kind"=>"branch",
            "package_name"=>"local"
          }
        ] 
        expect(expected_parsed).to eq(Array.new(8) { branch_package })
      end

      it "Parsing local manifests: exact" do
        expected_parsed = @my_plugin.get_local_packages("#{File.dirname(__FILE__)}/support/fixtures/local-parsing/Exact")
        branch_package = [
          "https://github.com/surfstudio/NodeKit.git",
          {
            "kind"=>"exactVersion",
            "package_name"=>"local"
          }
        ] 
        expect(expected_parsed).to eq(Array.new(8) { branch_package })
      end

      it "Parsing local manifests: revision" do
        expected_parsed = @my_plugin.get_local_packages("#{File.dirname(__FILE__)}/support/fixtures/local-parsing/Revision")
        branch_package = [
          "https://github.com/surfstudio/NodeKit.git",
          {
            "kind"=>"revision",
            "package_name"=>"local",
            "revision"=>"VERSION"
          }
        ] 
        expect(expected_parsed).to eq(Array.new(8) { branch_package })
      end

      it "Parsing local manifests: upToNextMajor" do
        expected_parsed = @my_plugin.get_local_packages("#{File.dirname(__FILE__)}/support/fixtures/local-parsing/upToNextMajor")
        branch_package = [
          "https://github.com/surfstudio/NodeKit.git",
          {
            "kind"=>"upToNextMajorVersion",
            "package_name"=>"local",
          }
        ] 
        expect(expected_parsed).to eq(Array.new(15) { branch_package })
      end

      it "Parsing local manifests: upToNextMinor" do
        expected_parsed = @my_plugin.get_local_packages("#{File.dirname(__FILE__)}/support/fixtures/local-parsing/upToNextMinor")
        branch_package = [
          "https://github.com/surfstudio/NodeKit.git",
          {
            "kind"=>"upToNextMinorVersion",
            "package_name"=>"local",
          }
        ] 
        expect(expected_parsed).to eq(Array.new(8) { branch_package })
      end

      it "Parsing local manifests: range" do
        expected_parsed = @my_plugin.get_local_packages("#{File.dirname(__FILE__)}/support/fixtures/local-parsing/Range")
        branch_package = [
          "https://github.com/surfstudio/NodeKit.git",
          {
            "kind"=>"range",
            "package_name"=>"local",
            "maximumVersion"=>"RIGHT"
          }
        ] 
        expect(expected_parsed).to eq(Array.new(7) { branch_package })
      end



    end
  end
end
