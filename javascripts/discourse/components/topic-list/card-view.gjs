import Component from "@glimmer/component";
import { on } from "@ember/modifier";
import TopicStatus from "discourse/components/topic-status";
import dIcon from "discourse/helpers/d-icon";
import dirSpan from "discourse/helpers/dir-span";
import ThumbnailImage from "./shared/thumbnail-image";
import AuthorInfo from "./shared/author-info";
import MetaActions from "./shared/meta-actions";

export default class CardView extends Component {
  get commentsCount() {
    const posts = this.args.topic.posts_count;
    if (typeof posts === "number" && posts > 0) {
      return Math.max(posts - 1, 0);
    }
    return 0;
  }

  <template>
    <article class="topic-card">
      <a
        href={{@firstPostUrl}}
        class="topic-card__link"
        {{on "click" @onClick}}
        {{on "auxclick" @onClick}}
      >
        {{#if @showAuthor}}
          <div class="topic-card__header">
            <div class="topic-card__author topic-author">
              <AuthorInfo
                @topic={{@topic}}
                @showUserFeedback={{@showUserFeedback}}
                @showActivity={{true}}
                @showCategory={{@showCategory}}
                @userClass="topic-card__author-user topic-author__user"
                @activityClass="topic-card__activity topic-author__activity"
                @categoryClass="topic-card__category topic-author__category"
              />
            </div>
          </div>
        {{/if}}

        <h3 class="topic-card__title">
          <TopicStatus @topic={{@topic}} />
          <span>{{@topic.title}}</span>
        </h3>

        {{#if @hasThumbnail}}
          <div class="topic-card__thumbnail">
            <ThumbnailImage
              @thumbnails={{@topic.thumbnails}}
              @fallbackSrc={{@fallbackSrc}}
              @srcSet={{@srcSet}}
              @width={{@width}}
              @height={{@height}}
              @placeholderIcon={{@placeholderIcon}}
            />
          </div>
        {{else if @topic.hasExcerpt}}
          <div class="topic-card__excerpt">
            {{dirSpan @topic.escapedExcerpt htmlSafe="true"}}
          </div>
        {{else}}
          <div class="topic-card__thumbnail">
            <div class="thumbnail-placeholder">
              {{dIcon @placeholderIcon}}
            </div>
          </div>
        {{/if}}

        <div class="topic-card__meta topic-meta">
          <@topicVoteControls @topic={{@topic}} />
          <span class="topic-card__meta-comments topic-meta__comments">
            {{dIcon "far-comment"}}
            {{this.commentsCount}}
          </span>
          <div class="topic-card__meta-actions topic-meta__actions">
            <MetaActions
              @isCardStyle={{true}}
              @isBookmarked={{@isBookmarked}}
              @onShare={{@onShare}}
              @onSave={{@onSave}}
              @onReport={{@onReport}}
              @onKeydown={{@onKeydown}}
            />
          </div>
        </div>
      </a>
    </article>
  </template>
}
