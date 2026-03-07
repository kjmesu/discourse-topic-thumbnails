import Component from "@glimmer/component";
import { on } from "@ember/modifier";
import concatClass from "discourse/helpers/concat-class";
import TopicStatus from "discourse/components/topic-status";
import { i18n } from "discourse-i18n";
import DropdownMenu from "discourse/components/dropdown-menu";
import DMenu from "discourse/float-kit/components/d-menu";
import dIcon from "discourse/helpers/d-icon";
import ThumbnailImage from "./shared/thumbnail-image";
import AuthorInfo from "./shared/author-info";
import MetaActions from "./shared/meta-actions";

export default class CompactView extends Component {
  get commentsCount() {
    const posts = this.args.topic.posts_count;
    if (typeof posts === "number" && posts > 0) {
      return Math.max(posts - 1, 0);
    }
    return 0;
  }

  <template>
    <a
      href={{@firstPostUrl}}
      class="topic-thumbnail-compact-link"
      aria-label={{@topic.title}}
      {{on "click" @onClick}}
      {{on "auxclick" @onClick}}
    >
      <div
        class={{concatClass
          "topic-list-thumbnail"
          (if @hasThumbnail "has-thumbnail" "no-thumbnail")
        }}
      >
        <ThumbnailImage
          @thumbnails={{@topic.thumbnails}}
          @fallbackSrc={{@fallbackSrc}}
          @srcSet={{@srcSet}}
          @width={{@width}}
          @height={{@height}}
          @placeholderIcon={{@placeholderIcon}}
        />
      </div>

      {{#if @showAuthor}}
        <div class="topic-compact-author topic-author">
          <AuthorInfo
            @topic={{@topic}}
            @showUserFeedback={{@showUserFeedback}}
            @showActivity={{true}}
            @showCategory={{@showCategory}}
            @userClass="topic-compact-author__user topic-author__user"
            @activityClass="topic-compact-author__activity topic-author__activity"
            @categoryClass="topic-compact-author__category topic-author__category"
          />
        </div>
      {{/if}}

      <h3 class="topic-compact__title">
        <TopicStatus @topic={{@topic}} />
        <span>{{@topic.title}}</span>
      </h3>

      <div class="topic-compact-meta topic-meta">
        <@topicVoteControls @topic={{@topic}} />
        <span class="topic-compact-meta__comments topic-meta__comments">
          {{this.commentsCount}}
          {{@commentsLabel}}
        </span>
        <div class="topic-compact-meta__actions topic-meta__actions">
          <MetaActions
            @isCardStyle={{false}}
            @isBookmarked={{@isBookmarked}}
            @onShare={{@onShare}}
            @onSave={{@onSave}}
            @onReport={{@onReport}}
            @onKeydown={{@onKeydown}}
          />
        </div>
        <DMenu
          @identifier={{@overflowIdentifier}}
          @icon="ellipsis"
          @ariaLabel={{i18n "topic_thumbnails.actions.more_actions"}}
          @triggerClass="topic-compact-meta__overflow"
          @modalForMobile={{true}}
          @onRegisterApi={{@onRegisterOverflowMenu}}
          @onShow={{@onOverflowShow}}
          @onClose={{@onOverflowClose}}
        >
          <:content>
            <div class="topic-compact-meta__overflow-menu">
              <DropdownMenu as |dropdown|>
                <dropdown.item>
                  <button
                    type="button"
                    class="topic-compact-meta__overflow-item"
                    {{on "click" @onOverflowShare}}
                  >
                    {{dIcon "share"}}
                    {{i18n "post.controls.share_action"}}
                  </button>
                </dropdown.item>
                <dropdown.item>
                  <button
                    type="button"
                    class="topic-compact-meta__overflow-item"
                    {{on "click" @onOverflowSave}}
                  >
                    {{if
                      @isBookmarked
                      @removeSaveLabel
                      @saveLabel
                    }}
                  </button>
                </dropdown.item>
                <dropdown.item>
                  <button
                    type="button"
                    class="topic-compact-meta__overflow-item"
                    {{on "click" @onOverflowReport}}
                  >
                    {{dIcon "flag"}}
                    {{@reportLabel}}
                  </button>
                </dropdown.item>
              </DropdownMenu>
            </div>
          </:content>
        </DMenu>
      </div>
    </a>
  </template>
}
