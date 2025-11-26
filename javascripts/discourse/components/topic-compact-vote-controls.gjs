import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import routeAction from "discourse/helpers/route-action";
import concatClass from "discourse/helpers/concat-class";
import { on } from "@ember/modifier";
import TopicCompactPostVotes from "./topic-compact-post-votes";

export default class TopicCompactVoteControls extends Component {
  @service siteSettings;

  get topic() {
    return this.args.topic;
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

  get hasPostVoteData() {
    return (
      this.topic?.first_post_id &&
      this.topic?.first_post_post_votes_count !== undefined &&
      this.topic?.first_post_post_votes_user_direction !== undefined &&
      this.topic?.first_post_post_votes_has_votes !== undefined
    );
  }

  get post() {
    if (!this.hasPostVoteData) {
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

  get shouldRender() {
    return Boolean(this.votingEnabledForTopic && this.post);
  }

  get containerClass() {
    return concatClass(
      "topic-compact-votes",
      this.post ? "has-post" : "is-loading"
    );
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
