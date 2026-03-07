# frozen_string_literal: true

RSpec.describe "Topic Thumbnails", type: :system do
  fab!(:theme) { upload_theme_component }
  fab!(:topics) { Fabricate.times(5, :topic) }
  fab!(:user)

  before { sign_in user }

  {
    "compact-style" => "compact",
    "card-style" => "card-style",
  }.each do |style, class_name|
    it "renders topic thumbnails in #{style} style" do
      theme.update_setting(:default_thumbnail_mode, style)
      theme.save!

      visit "/latest"

      expect(page).to have_css(".topic-list.topic-thumbnails-#{class_name}")
      expect(page).to have_css(".topic-list-thumbnail", count: 5)
    end
  end

  it "shows metadata actions in compact style" do
    theme.update_setting(:default_thumbnail_mode, "compact-style")
    theme.save!

    visit "/latest"

    expect(page).to have_css(".topic-compact-meta__share", text: "Share")
    expect(page).to have_css(".topic-compact-meta__action--save", text: "Save")
    expect(page).to have_css(".topic-compact-meta__action--report", text: "Report")
  end

  it "renders card style topics with inline controls" do
    theme.update_setting(:default_thumbnail_mode, "card-style")
    theme.save!

    visit "/latest"

    expect(page).to have_css(".topic-thumbnails-card-style .topic-card", count: 5)
    expect(page).to have_css(".topic-card__meta-comments .d-icon-far-comment")
    expect(page).to have_css(".topic-card__meta-action", text: "Share")
    expect(page).to have_css(".topic-card__meta-action .d-icon-flag")
  end

  it "allows selecting a manual view from the navigation dropdown" do
    visit "/latest"

    expect(page).to have_css(".topic-view-mode-selector__trigger")
    expect(page).to have_css(".topic-list.topic-thumbnails-compact")

    find(".topic-view-mode-selector__trigger").click
    find(".topic-view-mode-selector__option", text: "Card").click

    expect(page).to have_css(".topic-list.topic-thumbnails-card-style")
  end
end
