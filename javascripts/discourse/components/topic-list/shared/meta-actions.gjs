import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import dIcon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";

export default class MetaActions extends Component {
  get saveLabel() {
    return i18n(themePrefix("topic_thumbnails.actions.save"));
  }

  get removeSaveLabel() {
    return i18n(themePrefix("topic_thumbnails.actions.remove_saved"));
  }

  get reportLabel() {
    return i18n(themePrefix("topic_thumbnails.actions.report"));
  }

  <template>
    {{#if @isCardStyle}}
      <span
        role="button"
        tabindex="0"
        class="topic-card__meta-action topic-meta__action"
        {{on "click" @onShare}}
        {{on "keydown" (fn @onKeydown @onShare)}}
      >
        {{dIcon "share"}}
        {{i18n "post.controls.share_action"}}
      </span>
      <span
        role="button"
        tabindex="0"
        class="topic-card__meta-action topic-meta__action"
        {{on "click" @onSave}}
        {{on "keydown" (fn @onKeydown @onSave)}}
      >
        {{#if @isBookmarked}}
          {{dIcon "bookmark"}}
        {{else}}
          {{dIcon "far-bookmark"}}
        {{/if}}
      </span>
      <span
        role="button"
        tabindex="0"
        class="topic-card__meta-action topic-meta__action"
        {{on "click" @onReport}}
        {{on "keydown" (fn @onKeydown @onReport)}}
      >
        {{dIcon "flag"}}
      </span>
    {{else}}
      <span
        role="button"
        tabindex="0"
        class="topic-compact-meta__share topic-meta__action"
        {{on "click" @onShare}}
        {{on "keydown" (fn @onKeydown @onShare)}}
      >
        {{i18n "post.controls.share_action"}}
      </span>
      <span
        role="button"
        tabindex="0"
        class="topic-compact-meta__action topic-compact-meta__action--save topic-meta__action"
        {{on "click" @onSave}}
        {{on "keydown" (fn @onKeydown @onSave)}}
      >
        {{if @isBookmarked this.removeSaveLabel this.saveLabel}}
      </span>
      <span
        role="button"
        tabindex="0"
        class="topic-compact-meta__action topic-compact-meta__action--report topic-meta__action"
        {{on "click" @onReport}}
        {{on "keydown" (fn @onKeydown @onReport)}}
      >
        {{this.reportLabel}}
      </span>
    {{/if}}
  </template>
}
