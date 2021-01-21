namespace :mission do
  desc 'Creating a default whitelabel mission on app init'
  task default_whitelabel_mission: :environment do
    new_whitelabel_mission = mission
    new_whitelabel_mission.save(validate: false)
  end

  def dummy_image
    Rack::Test::UploadedFile.new(
      Rails.root.join('spec/fixtures/dummy_image.png').to_s,
      'image/png'
    )
  end

  def mission
    defaults = {
      name: 'test1',
      subtitle: 'test1',
      description: 'test1',
      image: dummy_image,
      logo: dummy_image,
      whitelabel: true,
      whitelabel_domain: ENV['APP_HOST'].presence || 'test.test',
      whitelabel_api_public_key: ENV['WHITELABEL_API_PUBLIC_KEY'],
      whitelabel_api_key: ENV['WHITELABEL_API_KEY']
    }
    Mission.new(defaults)
  end
end
