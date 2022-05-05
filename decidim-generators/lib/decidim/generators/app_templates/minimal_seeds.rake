# frozen_string_literal: true

require "decidim/faker/localized"
require "decidim/faker/internet"

namespace :minimal_seeds do

  desc "Initialize site and create and admin and a user"
  task :initialize_site, [:host] => [:environment] do |_t, args|
    host = args[:host] || ENV["DECIDIM_HOST"] ||"localhost"
    smtp_label = ENV["SMTP_FROM_LABEL"] || Faker::Twitter.unique.screen_name
    smtp_email = ENV["SMTP_FROM_EMAIL"] || Faker::Internet.email
    seeds_root = File.join(__dir__, "..", "..", "..", "decidim-core", "db", "seeds")
    participatory_processes_seeds_root = File.join(__dir__, "..", "..", "..", "decidim-participatory_processes", "db", "seeds")

    organization = Decidim::Organization.first || Decidim::Organization.create!(
      name: Faker::Company.name,
      twitter_handler: Faker::Hipster.word,
      facebook_handler: Faker::Hipster.word,
      instagram_handler: Faker::Hipster.word,
      youtube_handler: Faker::Hipster.word,
      github_handler: Faker::Hipster.word,
      smtp_settings: {
        from: "#{smtp_label} <#{smtp_email}>",
        from_email: smtp_email,
        from_label: smtp_label,
        user_name: smtp_label,
        encrypted_password: Decidim::AttributeEncryptor.encrypt("test1234"),
        address: host,
        port: ENV["DECIDIM_SMTP_PORT"] || "25"
      },
      host: host,
      external_domain_whitelist: ["decidim.org", "github.com"],
      description: Decidim::Faker::Localized.wrapped("<p>", "</p>") do
        Decidim::Faker::Localized.sentence(word_count: 15)
      end,
      default_locale: Decidim.default_locale,
      available_locales: Decidim.available_locales,
      reference_prefix: Faker::Name.suffix,
      available_authorizations: Decidim.authorization_workflows.map(&:name),
      users_registration_mode: :enabled,
      tos_version: Time.current,
      badges_enabled: true,
      user_groups_enabled: true,
      send_welcome_notification: true,
      file_upload_settings: Decidim::OrganizationSettings.default(:upload)
    )

    admin = Decidim::User.find_or_initialize_by(email: "admin@example.org")

    admin.update!(
      name: "Admin",
      nickname: "admin",
      password: "decidim123456",
      password_confirmation: "decidim123456",
      organization: organization,
      confirmed_at: Time.current,
      locale: I18n.default_locale,
      admin: true,
      tos_agreement: true,
      accepted_tos_version: organization.tos_version,
      admin_terms_accepted_at: Time.current
    )

    regular_user = Decidim::User.find_or_initialize_by(email: "user@example.org")

    regular_user.update!(
      name: "Usuario",
      nickname: "user",
      password: "decidim123456",
      password_confirmation: "decidim123456",
      confirmed_at: Time.current,
      locale: I18n.default_locale,
      organization: organization,
      tos_agreement: true,
      accepted_tos_version: organization.tos_version
    )

    Decidim::System::CreateDefaultContentBlocks.call(organization)

    hero_content_block = Decidim::ContentBlock.find_by(organization: organization, manifest_name: :hero, scope_name: :homepage)
    hero_content_block.images_container.background_image.attach(io: File.open(File.join(seeds_root, "homepage_image.jpg")), filename: "homepage_image.pdf")
    settings = {}
    welcome_text = Decidim::Faker::Localized.sentence(word_count: 5)
    settings = welcome_text.inject(settings) { |acc, (k, v)| acc.update("welcome_text_#{k}" => v) }
    hero_content_block.settings = settings
    hero_content_block.save!

    tos_page = Decidim::StaticPage.create(
      slug: "terms-and-conditions",
      organization: organization,
      title: Decidim::Faker::Localized.sentence(word_count: 2),
      content: Decidim::Faker::Localized.sentence(word_count: 10)
    )
    organization.tos_version = tos_page.updated_at
    organization.save!

    Decidim::ContentBlock.create(
      organization: organization,
      weight: 31,
      scope_name: :homepage,
      manifest_name: :highlighted_processes,
      published_at: Time.current
    )

    process_groups = []
    2.times do
      process_groups << Decidim::ParticipatoryProcessGroup.create!(
        title: Decidim::Faker::Localized.sentence(word_count: 3),
        description: Decidim::Faker::Localized.wrapped("<p>", "</p>") do
          Decidim::Faker::Localized.paragraph(sentence_count: 3)
        end,
        hashtag: Faker::Internet.slug,
        group_url: Faker::Internet.url,
        organization: organization,
        hero_image: ActiveStorage::Blob.create_and_upload!(
          io: File.open(File.join(participatory_processes_seeds_root, "city.jpeg")),
          filename: "hero_image.jpeg",
          content_type: "image/jpeg",
          metadata: nil
        ), # Keep after organization
        developer_group: Decidim::Faker::Localized.sentence(word_count: 1),
        local_area: Decidim::Faker::Localized.sentence(word_count: 2),
        meta_scope: Decidim::Faker::Localized.word,
        target: Decidim::Faker::Localized.sentence(word_count: 3),
        participatory_scope: Decidim::Faker::Localized.sentence(word_count: 1),
        participatory_structure: Decidim::Faker::Localized.sentence(word_count: 2)
      )
    end

    landing_page_content_blocks = [:title, :metadata, :cta, :highlighted_proposals, :highlighted_results, :highlighted_meetings, :stats, :participatory_processes]

    process_groups.each do |process_group|
      landing_page_content_blocks.each.with_index(1) do |manifest_name, index|
        Decidim::ContentBlock.create(
          organization: organization,
          scope_name: :participatory_process_group_homepage,
          manifest_name: manifest_name,
          weight: index,
          scoped_resource_id: process_group.id,
          published_at: Time.current
        )
      end
    end

    process_types = []
    2.times do
      process_types << Decidim::ParticipatoryProcessType.create!(
        title: Decidim::Faker::Localized.word,
        organization: organization
      )
    end

    2.times do |n|
      params = {
        title: Decidim::Faker::Localized.sentence(word_count: 5),
        slug: Decidim::Faker::Internet.unique.slug(words: nil, glue: "-"),
        subtitle: Decidim::Faker::Localized.sentence(word_count: 2),
        hashtag: "##{Faker::Lorem.word}",
        short_description: Decidim::Faker::Localized.wrapped("<p>", "</p>") do
          Decidim::Faker::Localized.sentence(word_count: 3)
        end,
        description: Decidim::Faker::Localized.wrapped("<p>", "</p>") do
          Decidim::Faker::Localized.paragraph(sentence_count: 3)
        end,
        organization: organization,
        hero_image: ActiveStorage::Blob.create_and_upload!(
          io: File.open(File.join(participatory_processes_seeds_root, "city.jpeg")),
          filename: "hero_image.jpeg",
          content_type: "image/jpeg",
          metadata: nil
        ), # Keep after organization
        banner_image: ActiveStorage::Blob.create_and_upload!(
          io: File.open(File.join(participatory_processes_seeds_root, "city2.jpeg")),
          filename: "banner_image.jpeg",
          content_type: "image/jpeg",
          metadata: nil
        ), # Keep after organization
        promoted: true,
        published_at: 2.weeks.ago,
        meta_scope: Decidim::Faker::Localized.word,
        developer_group: Decidim::Faker::Localized.sentence(word_count: 1),
        local_area: Decidim::Faker::Localized.sentence(word_count: 2),
        target: Decidim::Faker::Localized.sentence(word_count: 3),
        participatory_scope: Decidim::Faker::Localized.sentence(word_count: 1),
        participatory_structure: Decidim::Faker::Localized.sentence(word_count: 2),
        start_date: Date.current,
        end_date: 2.months.from_now,
        participatory_process_group: process_groups.sample,
        participatory_process_type: process_types.sample,
        scope: n.positive? ? nil : Decidim::Scope.reorder(Arel.sql("RANDOM()")).first
      }

      process = Decidim.traceability.perform_action!(
        "publish",
        Decidim::ParticipatoryProcess,
        organization.users.first,
        visibility: "all"
      ) do
        Decidim::ParticipatoryProcess.create!(params)
      end
      process.add_to_index_as_search_resource

      Decidim::ParticipatoryProcessStep.find_or_initialize_by(
        participatory_process: process,
        active: true
      ).update!(
        title: Decidim::Faker::Localized.sentence(word_count: 1, supplemental: false, random_words_to_add: 2),
        description: Decidim::Faker::Localized.wrapped("<p>", "</p>") do
          Decidim::Faker::Localized.paragraph(sentence_count: 3)
        end,
        start_date: 1.month.ago,
        end_date: 2.months.from_now
      )

      # Create users with specific roles
      Decidim::ParticipatoryProcessUserRole::ROLES.each do |role|
        email = "participatory_process_#{process.id}_#{role}@example.org"

        user = Decidim::User.find_or_initialize_by(email: email)
        user.update!(
          name: Faker::Name.name,
          nickname: Faker::Twitter.unique.screen_name,
          password: "decidim123456",
          password_confirmation: "decidim123456",
          organization: organization,
          confirmed_at: Time.current,
          locale: I18n.default_locale,
          tos_agreement: true
        )

        Decidim::ParticipatoryProcessUserRole.find_or_create_by!(
          user: user,
          participatory_process: process,
          role: role
        )
      end

      attachment_collection = Decidim::AttachmentCollection.create!(
        name: Decidim::Faker::Localized.word,
        description: Decidim::Faker::Localized.sentence(word_count: 5),
        collection_for: process
      )

      2.times do
        Decidim::Category.create!(
          name: Decidim::Faker::Localized.sentence(word_count: 5),
          description: Decidim::Faker::Localized.wrapped("<p>", "</p>") do
            Decidim::Faker::Localized.paragraph(sentence_count: 3)
          end,
          participatory_space: process
        )
      end
    end
  end
end
