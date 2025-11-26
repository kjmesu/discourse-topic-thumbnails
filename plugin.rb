# frozen_string_literal: true

after_initialize do
  next unless defined?(PostVotesVote)

  module ::TopicListItemPostVotesSerializerExtensions
    def post_votes_first_post
      return @post_votes_first_post if defined?(@post_votes_first_post)

      post =
        if object.association(:first_post).loaded?
          object.first_post
        elsif object.association(:posts).loaded?
          object.posts.find { |p| p.post_number == 1 }
        end

      post ||=
        Post
          .where(topic_id: object.id, post_number: 1)
          .select(:id, :topic_id, :post_votes_score)
          .first

      @post_votes_first_post = post
    end
  end

  ::TopicListItemSerializer.include TopicListItemPostVotesSerializerExtensions

  add_to_serializer(:topic_list_item, :first_post_post_votes_count) do
    next unless SiteSetting.post_votes_enabled
    post_votes_first_post&.post_votes_score.to_i
  end

  add_to_serializer(:topic_list_item, :first_post_post_votes_has_votes) do
    next unless SiteSetting.post_votes_enabled
    (post_votes_first_post&.post_votes_score.to_i || 0) > 0
  end

  add_to_serializer(:topic_list_item, :first_post_post_votes_user_direction) do
    next unless SiteSetting.post_votes_enabled
    next unless scope&.user
    post = post_votes_first_post
    next unless post

    PostVotesVote.find_by(
      votable_type: "Post",
      votable_id: post.id,
      user_id: scope.user.id
    )&.direction
  end
end
