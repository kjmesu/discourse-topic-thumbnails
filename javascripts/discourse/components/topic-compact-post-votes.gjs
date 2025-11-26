import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { fn } from "@ember/helper";
import concatClass from "discourse/helpers/concat-class";
import dIcon from "discourse/helpers/d-icon";
import PostVotesVoteControls from "discourse/plugins/discourse-post-voting-reddit-mode/discourse/components/post-votes-vote-controls";

export default class TopicCompactPostVotes extends PostVotesVoteControls {
  get disableButtons() {
    return this.disabled || this.loading;
  }

  get upvoteButtonClass() {
    return concatClass(
      "topic-compact-vote-button",
      "topic-compact-vote-button--up",
      this.votedUp && "is-active"
    );
  }

  get downvoteButtonClass() {
    return concatClass(
      "topic-compact-vote-button",
      "topic-compact-vote-button--down",
      this.votedDown && "is-active"
    );
  }

  @action
  handleVote(direction, event) {
    event?.preventDefault();
    event?.stopPropagation();

    if (this.disableButtons) {
      return;
    }

    const isUp = direction === "up";
    const isDown = direction === "down";

    if ((isUp && this.votedUp) || (isDown && this.votedDown)) {
      return this.removeVote(direction);
    }

    return this.vote(direction);
  }

  <template>
    <div class="topic-compact-votes__stack">
      <button
        type="button"
        class={{this.upvoteButtonClass}}
        disabled={{this.disableButtons}}
        aria-label={{i18n "topic_thumbnails.compact_votes.upvote"}}
        {{on "click" (fn this.handleVote "up")}}
      >
        {{dIcon "circle-up"}}
      </button>

      <span class="topic-compact-vote-count">
        {{this.count}}
      </span>

      <button
        type="button"
        class={{this.downvoteButtonClass}}
        disabled={{this.disableButtons}}
        aria-label={{i18n "topic_thumbnails.compact_votes.downvote"}}
        {{on "click" (fn this.handleVote "down")}}
      >
        {{dIcon "circle-down"}}
      </button>
    </div>
  </template>
}
