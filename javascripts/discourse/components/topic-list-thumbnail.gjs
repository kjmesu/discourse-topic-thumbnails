import Component from "@glimmer/component";
import { service } from "@ember/service";
import UserInfo from "discourse/components/user-info";
import coldAgeClass from "discourse/helpers/cold-age-class";
import concatClass from "discourse/helpers/concat-class";
import dIcon from "discourse/helpers/d-icon";
import formatDate from "discourse/helpers/format-date";
import TopicCompactVoteControls from "./topic-compact-vote-controls";

export default class TopicListThumbnail extends Component {
  @service topicThumbnails;

  responsiveRatios = [1, 1.5, 2];

  get commentsLabel() {
    return "comments";
  }

  // Make sure to update about.json thumbnail sizes if you change these variables
  get displayWidth() {
    return this.topicThumbnails.displayList ||
      this.topicThumbnails.displayCompactStyle
      ? settings.list_thumbnail_size
      : 400;
  }

  get topic() {
    return this.args.topic;
  }

  get hasThumbnail() {
    return !!this.topic.thumbnails;
  }

  get srcSet() {
    const srcSetArray = [];

    this.responsiveRatios.forEach((ratio) => {
      const target = ratio * this.displayWidth;
      const match = this.topic.thumbnails.find(
        (t) => t.url && t.max_width === target
      );
      if (match) {
        srcSetArray.push(`${match.url} ${ratio}x`);
      }
    });

    if (srcSetArray.length === 0) {
      srcSetArray.push(`${this.original.url} 1x`);
    }

    return srcSetArray.join(",");
  }

  get original() {
    return this.topic.thumbnails[0];
  }

  get width() {
    return this.original.width;
  }

  get isLandscape() {
    return this.original.width >= this.original.height;
  }

  get height() {
    return this.original.height;
  }

  get fallbackSrc() {
    const largeEnough = this.topic.thumbnails.filter((t) => {
      if (!t.url) {
        return false;
      }
      return t.max_width > this.displayWidth * this.responsiveRatios.lastObject;
    });

    if (largeEnough.lastObject) {
      return largeEnough.lastObject.url;
    }

    return this.original.url;
  }

  get url() {
    return this.topic.get("linked_post_number")
      ? this.topic.urlForPostNumber(this.topic.get("linked_post_number"))
      : this.topic.get("lastUnreadUrl");
  }

  get showCompactAuthor() {
    return this.topicThumbnails.displayCompactStyle && this.topic?.creator;
  }

  get commentsCount() {
    const replies = this.topic.reply_count;
    if (typeof replies === "number" && replies > 0) {
      return replies;
    }

    const posts = this.topic.posts_count;
    if (typeof posts === "number") {
      return Math.max(posts - 1, 0);
    }

    return 0;
  }

  <template>
    {{#if this.topicThumbnails.displayCompactStyle}}
      <a
        href={{this.url}}
        class="topic-thumbnail-compact-link"
        aria-label={{this.topic.title}}
      >
        <div
          class={{concatClass
            "topic-list-thumbnail"
            (if this.hasThumbnail "has-thumbnail" "no-thumbnail")
          }}
        >
          {{#if this.hasThumbnail}}
            <img
              class="background-thumbnail"
              src={{this.fallbackSrc}}
              srcset={{this.srcSet}}
              width={{this.width}}
              height={{this.height}}
              loading="lazy"
              alt=""
            />
            <img
              class="main-thumbnail"
              src={{this.fallbackSrc}}
              srcset={{this.srcSet}}
              width={{this.width}}
              height={{this.height}}
              loading="lazy"
              alt=""
            />
          {{else}}
            <div class="thumbnail-placeholder">
              {{dIcon settings.placeholder_icon}}
            </div>
          {{/if}}
        </div>

        {{#if this.showCompactAuthor}}
          <div class="topic-compact-author">
            <UserInfo
              @user={{this.topic.creator}}
              @includeLink={{true}}
              @includeAvatar={{true}}
              @size="small"
              class="topic-compact-author__user"
            />
            <span class="topic-compact-author__activity">
              {{formatDate this.topic.createdAt format="tiny" noTitle="true"}}
              ago
            </span>
          </div>
        {{/if}}

        <div class="topic-compact-meta">
          <TopicCompactVoteControls @topic={{this.topic}} />
          <span class="topic-compact-meta__comments">
            {{this.commentsCount}}
            {{this.commentsLabel}}
          </span>
        </div>
      </a>
    {{else}}
      <div
        class={{concatClass
          "topic-list-thumbnail"
          (if this.hasThumbnail "has-thumbnail" "no-thumbnail")
        }}
      >
        {{#if this.hasThumbnail}}
          <img
            class="background-thumbnail"
            src={{this.fallbackSrc}}
            srcset={{this.srcSet}}
            width={{this.width}}
            height={{this.height}}
            loading="lazy"
            alt=""
          />
          <img
            class="main-thumbnail"
            src={{this.fallbackSrc}}
            srcset={{this.srcSet}}
            width={{this.width}}
            height={{this.height}}
            loading="lazy"
            alt=""
          />
        {{else}}
          <div class="thumbnail-placeholder">
            {{dIcon settings.placeholder_icon}}
          </div>
        {{/if}}
      </div>
    {{/if}}

    {{#if this.topicThumbnails.showLikes}}
      <div class="topic-thumbnail-likes">
        {{dIcon "heart"}}
        <span class="number">
          {{this.topic.like_count}}
        </span>
      </div>
    {{/if}}

    {{#if this.topicThumbnails.displayBlogStyle}}
      <div class="topic-thumbnail-blog-data">
        <div class="topic-thumbnail-blog-data-views">
          {{dIcon "eye"}}
          <span class="number">
            {{this.topic.views}}
          </span>
        </div>
        <div class="topic-thumbnail-blog-data-likes">
          {{dIcon "heart"}}
          <span class="number">
            {{this.topic.like_count}}
          </span>
        </div>
        <div class="topic-thumbnail-blog-data-comments">
          {{dIcon "comment"}}
          <span class="number">
            {{this.topic.reply_count}}
          </span>
        </div>
        <div
          class={{concatClass
            "topic-thumbnail-blog-data-activity"
            "activity"
            (coldAgeClass
              this.topic.createdAt startDate=this.topic.bumpedAt class=""
            )
          }}
          title={{this.topic.bumpedAtTitle}}
        >
          <a class="post-activity" href={{this.topic.lastPostUrl}}>
            {{~formatDate this.topic.bumpedAt format="tiny" noTitle="true"~}}
          </a>
        </div>
      </div>
    {{/if}}
  </template>
}
