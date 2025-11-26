import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import routeAction from "discourse/helpers/route-action";
import concatClass from "discourse/helpers/concat-class";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import didUpdate from "@ember/render-modifiers/modifiers/did-update";
import { on } from "@ember/modifier";
import { ajax } from "discourse/lib/ajax";
import { next } from "@ember/runloop";
import TopicCompactPostVotes from "./topic-compact-post-votes";
import { queueVoteRequest } from "../lib/topic-compact-vote-request-queue";

export default class TopicCompactVoteControls extends Component {
  @service siteSettings;

  @tracked remotePost;
  _loadedPostId = null;
  _loadedTopicId = null;

  get topic() {
    return this.args.topic;
  }

  get topicId() {
    return this.topic?.id;
  }

  get categoryId() {
    return (
      this.topic?.category_id ||
      this.topic?.categoryId ||
      this.topic?.category?.id
    );
  }

  get enabledCategoryIds() {
    const raw = this.siteSettings.post_votes_enabled_categories;

    if (!raw) {
      return [];
    }

    const values = Array.isArray(raw) ? raw : raw.split("|");

    return values
      .map((id) => parseInt(id, 10))
      .filter((id) => Number.isInteger(id));
  }

  get votingEnabledForTopic() {
    if (!this.siteSettings.post_votes_enabled) {
      return false;
    }

    const ids = this.enabledCategoryIds;
    if (!ids.length) {
      return true;
    }

    const categoryId = this.categoryId;
    return !!categoryId && ids.includes(categoryId);
  }

  get hasSerializedVoteData() {
    return (
      this.topic?.first_post_id &&
      this.topic?.first_post_post_votes_count !== undefined &&
      this.topic?.first_post_post_votes_user_direction !== undefined &&
      this.topic?.first_post_post_votes_has_votes !== undefined
    );
  }

  get serializedPost() {
    if (!this.hasSerializedVoteData) {
      return null;
    }

    return {
      id: this.topic.first_post_id,
      topic: {
        archived: this.topic?.archived,
        closed: this.topic?.closed,
      },
      post_votes_count: this.topic.first_post_post_votes_count,
      post_votes_user_direction:
        this.topic.first_post_post_votes_user_direction,
      post_votes_has_votes: this.topic.first_post_post_votes_has_votes,
    };
  }

  get post() {
    return this.serializedPost || this.remotePost;
  }

  get shouldRender() {
    return Boolean(this.votingEnabledForTopic && this.post);
  }

  get containerClass() {
    return concatClass(
      "topic-compact-votes",
      this.post ? "has-post" : "is-loading"
    );
  }

  _decoratePost(post) {
    if (!post) {
      return null;
    }

    post.topic ||= {
      archived: this.topic?.archived,
      closed: this.topic?.closed,
    };

    return post;
  }

  async _loadPostById(postId) {
    if (!postId || postId === this._loadedPostId) {
      return;
    }

    this._loadedPostId = postId;
    this.remotePost = null;

    try {
      const post = await queueVoteRequest(`post-${postId}`, () =>
        ajax(`/posts/${postId}.json`, {
          data: { skip_rate_limit: true },
        })
      );
      this.remotePost = this._decoratePost(post);
    } catch (error) {
      this.remotePost = null;
      this._loadedPostId = null;
      throw error;
    }
  }

  async _loadFirstPostByTopicId(topicId) {
    if (!topicId || topicId === this._loadedTopicId) {
      return;
    }

    this._loadedTopicId = topicId;

    try {
      const post = await queueVoteRequest(`topic-${topicId}`, () =>
        ajax(`/posts/by_number/${topicId}/1.json`, {
          data: { skip_rate_limit: true },
        })
      );
      this._loadedPostId = post.id;
      this.remotePost = this._decoratePost(post);
    } catch (error) {
      this._loadedTopicId = null;
      throw error;
    }
  }

  @action
  async loadPostForVoting() {
    if (!this.votingEnabledForTopic || this.serializedPost) {
      return;
    }

    try {
      if (this.topic?.first_post_id) {
        await this._loadPostById(this.topic.first_post_id);
      } else {
        await this._loadFirstPostByTopicId(this.topicId);
      }
    } catch (error) {
      if (error?.status === 429) {
        this._loadedPostId = null;
        this._loadedTopicId = null;
        next(this, this.loadPostForVoting);
      } else {
        console.warn("topic-compact-votes: failed to load post", {
          topicId: this.topicId,
          postId: this.topic?.first_post_id,
          error,
        });
      }
    }
  }

  @action
  stopCardNavigation(event) {
    event.preventDefault();
    event.stopPropagation();
  }

  <template>
    {{#if this.votingEnabledForTopic}}
      <div
        class={{this.containerClass}}
        {{didInsert this.loadPostForVoting}}
        {{didUpdate this.loadPostForVoting this.topicId this.topic?.first_post_id this.categoryId}}
        {{on "click" this.stopCardNavigation}}
      >
        {{#if this.shouldRender}}
          <TopicCompactPostVotes
            @post={{this.post}}
            @showLogin={{routeAction "showLogin"}}
          />
        {{/if}}
      </div>
    {{/if}}
  </template>
}
