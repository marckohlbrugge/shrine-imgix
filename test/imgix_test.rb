require "test_helper"
require "shrine/storage/linter"
require "shrine/storage/s3"
require "down"

describe Shrine::Storage::Imgix do
  def imgix(options = {})
    options[:storage]          ||= s3
    options[:host]             ||= ENV.fetch("IMGIX_HOST")
    options[:api_key]          ||= ENV.fetch("IMGIX_API_KEY")
    options[:secure_url_token] ||= ENV.fetch("IMGIX_SECURE_URL_TOKEN", nil)

    Shrine::Storage::Imgix.new(options)
  end

  def s3(options = {})
    options[:bucket]            ||= ENV.fetch("S3_BUCKET")
    options[:region]            ||= ENV.fetch("S3_REGION")
    options[:access_key_id]     ||= ENV.fetch("S3_ACCESS_KEY_ID")
    options[:secret_access_key] ||= ENV.fetch("S3_SECRET_ACCESS_KEY")
    options[:prefix]            ||= ENV.fetch("S3_PREFIX")

    Shrine::Storage::S3.new(options)
  end

  before do
    @imgix = imgix
  end

  after do
    @imgix.clear!
  end

  it "passes the linter" do
    Shrine::Storage::Linter.call(@imgix)
  end

  describe "#url" do
    it "creates URL parameters out of options" do
      url = @imgix.url("image.jpg", w: 150)

      assert_includes url, ENV["IMGIX_HOST"]
      assert_includes url, "w=150"
    end

    it "creates a valid downloadable URL" do
      @imgix.upload(image, "image.jpg", shrine_metadata: {"mime_type" => "image/jpeg"})
      url = @imgix.url("image.jpg", w: 150)
      tempfile = Down.download(url)

      assert_equal "image/jpeg", tempfile.content_type
    end

    it "includes prefix in the URL when :include_prefix is set" do
      storage = s3(prefix: "prefix")
      refute_includes imgix(storage: storage).url("image.jpg"), "prefix"
      assert_includes imgix(storage: storage, include_prefix: true).url("image.jpg"), "prefix"
    end
  end

  describe "#presign" do
    it "delegates to underlying storage" do
      presign = @imgix.presign("image.jpg")
      assert_instance_of String, presign.url
      assert_instance_of Hash,   presign.fields
    end
  end
end
