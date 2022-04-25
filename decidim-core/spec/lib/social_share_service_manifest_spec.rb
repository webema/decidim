# frozen_string_literal: true

require "spec_helper"

module Decidim
  describe SocialShareServiceManifest do
    subject { described_class.new }

    before do
      subject.name = "foo"
      subject.icon = "foo.svg"
      subject.share_uri = "https://example.com/share?url=%{url}"
    end

    describe "attributes" do
      context "when all the values are correct" do
        it { is_expected.to be_valid }
      end

      context "without a name" do
        before do
          subject.name = nil
        end

        it { is_expected.to be_invalid }
      end

      context "without an icon" do
        before do
          subject.icon = nil
        end

        it { is_expected.to be_invalid }
      end

      context "without a share_uri" do
        before do
          subject.share_uri = nil
        end

        it { is_expected.to be_invalid }
      end

      context "without a url variable in share_uri" do
        before do
          subject.share_uri = "https://example.com/share"
        end

        it { is_expected.to be_invalid }
      end
    end

    describe "#formatted_share_uri" do
      it "returns the correct formatted uri" do
        expected_share_uri = "https://example.com/share?url=https://other.example.org"
        expect(subject.formatted_share_uri("Bar", { url: "https://other.example.org" })).to eq(expected_share_uri)
      end

      context "when there's a title" do
        before do
          subject.share_uri = "https://example.com/share?title=%{title}&url=%{url}"
        end

        it "returns the correct formatted uri" do
          expected_share_uri = "https://example.com/share?title=Bar&url=https://other.example.org"
          expect(subject.formatted_share_uri("Bar", { url: "https://other.example.org" })).to eq(expected_share_uri)
        end
      end
    end

    describe "#icon_path" do
      before do
        subject.icon = "email.svg"
      end

      it "returns the correct path" do
        expect(subject.icon_path).to match(%r{/packs-test/media/images/email-.*\.svg})
      end
    end
  end
end
