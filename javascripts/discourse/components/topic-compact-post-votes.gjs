import { action } from "@ember/object";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { htmlSafe } from "@ember/template";
import concatClass from "discourse/helpers/concat-class";
import { i18n } from "discourse-i18n";
import PostVotesVoteControls from "discourse/plugins/discourse-post-voting-reddit-mode/discourse/components/post-votes-vote-controls";

const circleUpSvg = `<svg class="topic-compact-vote-icon" viewBox="0 0 512 512" aria-hidden="true" focusable="false"><path d="M256 512A256 256 0 1 0 256 0a256 256 0 1 0 0 512zm11.3-395.3l112 112c4.6 4.6 5.9 11.5 3.5 17.4s-8.3 9.9-14.8 9.9l-64 0 0 96c0 17.7-14.3 32-32 32l-32 0c-17.7 0-32-14.3-32-32l0-96-64 0c-6.5 0-12.3-3.9-14.8-9.9s-1.1-12.9 3.5-17.4l112-112c6.2-6.2 16.4-6.2 22.6 0z"></path></svg>`;
const circleDownSvg = `<svg class="topic-compact-vote-icon" viewBox="0 0 512 512" aria-hidden="true" focusable="false"><path d="M256 0a256 256 0 1 0 0 512A256 256 0 1 0 256 0zM244.7 395.3l-112-112c-4.6-4.6-5.9-11.5-3.5-17.4s8.3-9.9 14.8-9.9l64 0 0-96c0-17.7 14.3-32 32-32l32 0c17.7 0 32 14.3 32 32l0 96 64 0c6.5 0 12.3 3.9 14.8 9.9s1.1 12.9-3.5 17.4l-112 112c-6.2 6.2-16.4 6.2-22.6 0z"></path></svg>`;

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
