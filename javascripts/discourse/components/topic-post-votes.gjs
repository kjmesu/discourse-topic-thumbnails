import Component from "@glimmer/component";

const POST_VOTE_CONTROLS_PATH =
  "discourse/plugins/discourse-post-voting-reddit-mode/discourse/components/post-votes-vote-controls";

export function hasPostVoteControls() {
  return require.has(POST_VOTE_CONTROLS_PATH);
}

export default class TopicPostVotes extends Component {
  get pluginClass() {
    return require.has(POST_VOTE_CONTROLS_PATH)
      ? require(POST_VOTE_CONTROLS_PATH).default
      : null;
  }

  <template>
    {{#if this.pluginClass}}
      <this.pluginClass
        @post={{@post}}
        @showLogin={{@showLogin}}
      />
    {{/if}}
  </template>
}
