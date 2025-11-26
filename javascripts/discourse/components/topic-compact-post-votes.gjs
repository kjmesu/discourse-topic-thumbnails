import { action } from "@ember/object";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { htmlSafe } from "@ember/template";
import concatClass from "discourse/helpers/concat-class";
import { i18n } from "discourse-i18n";
import PostVotesVoteControls from "discourse/plugins/discourse-post-voting-reddit-mode/discourse/components/post-votes-vote-controls";

const circleUpSvg = `<svg class="topic-compact-vote-icon" viewBox="0 0 512 512" aria-hidden="true" focusable="false"><path fill="currentColor" d="M256 48a208 208 0 1 1 0 416 208 208 0 1 1 0-416zm0 464A256 256 0 1 0 256 0a256 256 0 1 0 0 512zM151.2 217.4c-4.6 4.2-7.2 10.1-7.2 16.4c0 12.3 10 22.3 22.3 22.3l41.7 0 0 96c0 17.7 14.3 32 32 32l32 0c17.7 0 32-14.3 32-32l0-96 41.7 0c12.3 0 22.3-10 22.3-22.3c0-6.2-2.6-12.1-7.2-16.4l-91-84c-3.8-3.5-8.7-5.4-13.9-5.4s-10.1 1.9-13.9 5.4l-91 84z"></path></svg>`;
const circleDownSvg = `<svg class="topic-compact-vote-icon" viewBox="0 0 512 512" aria-hidden="true" focusable="false"><path fill="currentColor" d="M256 464a208 208 0 1 1 0-416 208 208 0 1 1 0 416zM256 0a256 256 0 1 0 0 512A256 256 0 1 0 256 0zM128 256l0 32L256 416 384 288l0-32-80 0 0-128-96 0 0 128-80 0z"></path></svg>`;

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

  get upIcon() {
    return htmlSafe(circleUpSvg);
  }

  get downIcon() {
    return htmlSafe(circleDownSvg);
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
        {{this.upIcon}}
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
        {{this.downIcon}}
      </button>
    </div>
  </template>
}
