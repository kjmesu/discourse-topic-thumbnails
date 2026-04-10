import Component from "@glimmer/component";
import { on } from "@ember/modifier";
import { i18n } from "discourse-i18n";
import DropdownMenu from "discourse/components/dropdown-menu";
import DMenu from "discourse/float-kit/components/d-menu";
import concatClass from "discourse/helpers/concat-class";
import dIcon from "discourse/helpers/d-icon";
import TopicStatus from "discourse/components/topic-status";
import UserInfo from "discourse/components/user-info";
import ThumbnailImage from "./shared/thumbnail-image";
import AuthorInfo from "./shared/author-info";
import InlineUserFeedback from "../inline-user-feedback";
import MetaActions from "./shared/meta-actions";

export default class TileView extends Component {
  get commentsCount() {
    const posts = this.args.topic.posts_count;
    if (typeof posts === "number" && posts > 0) {
      return Math.max(posts - 1, 0);
    }
    return 0;
  }

  <template>
    <article class="topic-tile">
      <a
        href={{@firstPostUrl}}
        class="topic-tile__link"
        {{on "click" @onClick}}
        {{on "auxclick" @onClick}}
      >
        {{#if @showAuthor}}
          <div class="topic-tile__header topic-author">
            <UserInfo
              @user={{@topic.creator}}
              @includeLink={{true}}
              @includeAvatar={{true}}
              @size="small"
              class="topic-tile__header-user topic-author__user"
            />
            {{#if @showUserFeedback}}
              <InlineUserFeedback
                @shouldRender={{true}}
                @rating={{@topic.creator.average_rating}}
                @count={{@topic.creator.total_trade_count}}
              />
            {{/if}}
          </div>
        {{/if}}

        <div
          class={{concatClass
            "topic-tile__thumbnail"
            "topic-list-thumbnail"
            (if @hasThumbnail "has-thumbnail" "no-thumbnail")
          }}
        >
          {{#if @hasThumbnail}}
            <ThumbnailImage
              @thumbnails={{@topic.thumbnails}}
              @fallbackSrc={{@fallbackSrc}}
              @srcSet={{@srcSet}}
              @width={{@width}}
              @height={{@height}}
              @placeholderIcon={{@placeholderIcon}}
            />
          {{else}}
            <div class="thumbnail-placeholder">
              {{dIcon @placeholderIcon}}
            </div>
          {{/if}}
        </div>

        {{#if @showAuthor}}
          <div class="topic-tile__author topic-author">
            <AuthorInfo
              @topic={{@topic}}
              @showUserFeedback={{false}}
              @showActivity={{true}}
              @showCategory={{@showCategory}}
              @compactDate={{true}}
              @userClass="topic-tile__author-user topic-author__user"
              @activityClass="topic-tile__activity topic-author__activity"
              @categoryClass="topic-tile__category topic-author__category"
            />
          </div>
        {{/if}}

        <h3 class="topic-tile__title">
          <TopicStatus @topic={{@topic}} />
          <span>{{@topic.title}}</span>
        </h3>

        <div class="topic-tile__meta topic-meta">
          <@topicVoteControls @topic={{@topic}} />
          <span class="topic-tile__meta-comments topic-meta__comments">
            {{dIcon "far-comment"}}
            {{this.commentsCount}}
          </span>
          <div class="topic-tile__meta-actions topic-meta__actions">
            <MetaActions
              @isCardStyle={{false}}
              @iconOnly={{true}}
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
            @triggerClass="topic-tile-meta__overflow"
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
    </article>
  </template>
}
