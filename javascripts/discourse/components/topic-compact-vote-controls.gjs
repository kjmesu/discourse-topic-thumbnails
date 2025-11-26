import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import routeAction from "discourse/helpers/route-action";
import concatClass from "discourse/helpers/concat-class";
import didUpdate from "@ember/render-modifiers/modifiers/did-update";
import { on } from "@ember/modifier";
import TopicCompactPostVotes from "./topic-compact-post-votes";

export default class TopicCompactVoteControls extends Component {
  @service store;
  @service siteSettings;

  @tracked post;

  _loadedPostId = null;

  constructor() {
    super(...arguments);
    this.loadPostForVoting();
  }

  get postId() {
    return this.args.topic?.first_post_id;
  }

  get categoryId() {
    return (
      this.args.topic?.category_id ||
      this.args.topic?.categoryId ||
      this.args.topic?.category?.id
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
  async loadPostForVoting() {
    if (!this.votingEnabledForTopic) {
      return;
    }

    const postId = this.postId;

    if (!postId || postId === this._loadedPostId) {
      return;
    }

    this._loadedPostId = postId;
    this.post = null;

    try {
      const post = await this.store.find("post", postId);
      post.topic ||= this.args.topic;
      this.post = post;
    } catch {
      this.post = null;
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
        {{didUpdate this.loadPostForVoting @topic}}
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
