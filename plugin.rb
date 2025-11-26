# frozen_string_literal: true

after_initialize do
  next unless defined?(PostVotesVote)

  add_to_serializer(:topic_list_item, :first_post_post_votes_count) do
    next unless SiteSetting.post_votes_enabled
    object.first_post&.post_votes_score.to_i
  end

  add_to_serializer(:topic_list_item, :first_post_post_votes_has_votes) do
    next unless SiteSetting.post_votes_enabled
    (object.first_post&.post_votes_score.to_i || 0) > 0
  end

  add_to_serializer(:topic_list_item, :first_post_post_votes_user_direction) do
    next unless SiteSetting.post_votes_enabled
    next unless scope&.user
    next unless object.first_post

    PostVotesVote.find_by(
      votable_type: "Post",
      votable_id: object.first_post.id,
      user_id: scope.user.id
    )&.direction
  end
end
