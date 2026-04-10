import Component from "@glimmer/component";
import EmberObject, { action } from "@ember/object";
import { cached, tracked } from "@glimmer/tracking";
import { service } from "@ember/service";
import FlagModal from "discourse/components/modal/flag";
import { getAbsoluteURL } from "discourse/lib/get-url";
import { clipboardCopy } from "discourse/lib/utilities";
import DiscourseURL from "discourse/lib/url";
import { wantsNewWindow } from "discourse/lib/intercept-click";
import { i18n } from "discourse-i18n";
import TopicFlag from "discourse/lib/flag-targets/topic-flag";
import { themePrefix } from "virtual:theme";
import { BookmarkFormData } from "discourse/lib/bookmark-form-data";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import Bookmark from "discourse/models/bookmark";
import TopicVoteControls from "./topic-vote-controls";
import CardView from "./topic-list/card-view";
import CompactView from "./topic-list/compact-view";
import TileView from "./topic-list/tile-view";

const OVERFLOW_EVENT = "topic-thumbnails:overflow-open";
const RESPONSIVE_RATIOS = [1, 1.5, 2];

export default class TopicListThumbnail extends Component {
  topicVoteControlsComponent = TopicVoteControls;
  @service topicThumbnails;
  @service bookmarkApi;
  @service currentUser;
  @service modal;
  @service toasts;

  @tracked bookmarkId;
  @tracked isBookmarkedState = false;
  @tracked isBookmarking = false;
  @tracked isCompactOverflowOpen = false;
  #overflowListener;
  #compactOverflowMenu;

  get optimizedThumbnails() {
    return this.topic.thumbnails?.filter((t) => t.max_width !== null) || [];
  }

  @cached
  get sortedOptimizedThumbnails() {
    return [...this.optimizedThumbnails].sort(
      (a, b) => a.max_width - b.max_width
    );
  }

  constructor() {
    super(...arguments);
    this.bookmarkId = this.topic?.bookmark_id;
    this.isBookmarkedState = !!this.topic?.bookmarked;
    this.#overflowListener = (event) => {
      const detail = event?.detail;
      if (detail !== this.#compactOverflowKey()) {
        this.closeOverflowMenus();
      }
    };
    window.addEventListener(OVERFLOW_EVENT, this.#overflowListener);
  }

  willDestroy() {
    super.willDestroy?.();
    window.removeEventListener(OVERFLOW_EVENT, this.#overflowListener);
  }

  get commentsLabel() {
    return "comments";
  }

  get topic() {
    return this.args.topic;
  }

  get hasThumbnail() {
    if (!this.topic.thumbnails) {
      return false;
    }

    const enabledCategories = this.topicThumbnails.enabledCategoriesList;
    if (enabledCategories.length === 0) {
      return true;
    }

    return enabledCategories.includes(this.topic.category_id);
  }

  get placeholderIcon() {
    const categoryId = this.topic.category_id;
    const customIcon =
      this.topicThumbnails.getPlaceholderIconForCategory(categoryId);
    return customIcon || settings.placeholder_icon;
  }

  get displayWidth() {
    if (this.topicThumbnails.displayCardStyle) {
      return 800;
    }

    if (
      this.topicThumbnails.displayCompactStyle ||
      this.topicThumbnails.displayTileStyle
    ) {
      return settings.list_thumbnail_size;
    }

    return 400;
  }

  @cached
  get srcSet() {
    const srcSetArray = [];

    RESPONSIVE_RATIOS.forEach((ratio) => {
      const target = ratio * this.displayWidth;
      const match = this.optimizedThumbnails.find(
        (t) => t.url && t.max_width === target
      );
      if (match) {
        srcSetArray.push(`${match.url} ${ratio}x`);
      }
    });

    if (srcSetArray.length === 0) {
      const smallest = this.sortedOptimizedThumbnails[0];
      if (smallest?.url) {
        srcSetArray.push(`${smallest.url} 1x`);
      }
    }

    return srcSetArray.join(",");
  }

  @cached
  get smallestOptimized() {
    const smallest = this.sortedOptimizedThumbnails.find((t) => t.url);
    return smallest || this.topic.thumbnails?.[0];
  }

  @cached
  get width() {
    return this.smallestOptimized?.width;
  }

  @cached
  get height() {
    return this.smallestOptimized?.height;
  }

  @cached
  get fallbackSrc() {
    const minWidth = this.displayWidth * 2;
    const largeEnough = this.sortedOptimizedThumbnails.find(
      (t) => t.url && t.max_width >= minWidth
    );

    if (largeEnough) {
      return largeEnough.url;
    }

    const largest = [...this.sortedOptimizedThumbnails]
      .reverse()
      .find((t) => t.url);

    return largest?.url;
  }

  get firstPostUrl() {
    return this.topic.urlForPostNumber(1);
  }

  get shareUrl() {
    const sharePath = this.topic?.shareUrl || this.topic?.url;
    return sharePath ? getAbsoluteURL(sharePath) : null;
  }

  get showCardAuthor() {
    return this.topicThumbnails.displayCardStyle && this.topic?.creator;
  }

  get showCompactAuthor() {
    return this.topicThumbnails.displayCompactStyle && this.topic?.creator;
  }

  get showTileAuthor() {
    return this.topicThumbnails.displayTileStyle && this.topic?.creator;
  }

  get showCategory() {
    return !this.topicThumbnails.isViewingCategory && this.topic?.category;
  }

  get showUserFeedback() {
    return settings.show_user_feedback && this.topic?.creator;
  }

  get isBookmarked() {
    return this.isBookmarkedState;
  }

  get saveLabel() {
    return i18n(themePrefix("topic_thumbnails.actions.save"));
  }

  get removeSaveLabel() {
    return i18n(themePrefix("topic_thumbnails.actions.remove_saved"));
  }

  get reportLabel() {
    return i18n(themePrefix("topic_thumbnails.actions.report"));
  }

  #compactOverflowKey() {
    return `compact-${this.topic?.id ?? "unknown"}`;
  }

  #announceCompactOverflow() {
    window.dispatchEvent(
      new CustomEvent(OVERFLOW_EVENT, { detail: this.#compactOverflowKey() })
    );
  }

  get compactOverflowIdentifier() {
    return this.#compactOverflowKey();
  }

  get tileOverflowIdentifier() {
    return `tile-${this.topic?.id ?? "unknown"}`;
  }

  @action
  async copyTopicLink(event) {
    event?.preventDefault();
    event?.stopPropagation();

    if (!this.shareUrl) {
      return;
    }

    try {
      await clipboardCopy(this.shareUrl);
      this.toasts.success({
        duration: "short",
        data: { message: i18n("post.controls.link_copied") },
      });
    } catch (error) {
      // clipboard API already surfaces errors
    }
  }

  @action
  handleActionKeydown(callback, event) {
    if (event.key === "Enter" || event.key === " ") {
      callback.call(this, event);
    }
  }

  @action
  async toggleSave(event) {
    event?.preventDefault();
    event?.stopPropagation();

    if (!this.currentUser) {
      window.location = "/login";
      return;
    }

    if (this.isBookmarking) {
      return;
    }

    this.isBookmarking = true;
    try {
      if (this.isBookmarked) {
        await this.#removeBookmark();
      } else {
        await this.#createBookmark();
      }
    } finally {
      this.isBookmarking = false;
    }
  }

  async #createBookmark() {
    try {
      const bookmark = Bookmark.createFor(
        this.currentUser,
        "Topic",
        this.topic.id
      );
      const formData = new BookmarkFormData(bookmark);
      const savedData = await this.bookmarkApi.create(formData);
      this.bookmarkId = savedData.id;
      this.topic.bookmarked = true;
      this.isBookmarkedState = true;
    } catch (error) {
      popupAjaxError(error);
    }
  }

  async #removeBookmark() {
    try {
      if (this.bookmarkId) {
        await this.bookmarkApi.delete(this.bookmarkId);
      } else {
        await ajax(`/t/${this.topic.id}/remove_bookmarks`, { type: "PUT" });
      }
      this.bookmarkId = null;
      this.topic.bookmarked = false;
      this.isBookmarkedState = false;
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  async reportTopic(event) {
    event?.preventDefault();
    event?.stopPropagation();

    if (!this.currentUser) {
      window.location = "/login";
      return;
    }

    let flagModel = this.topic;

    if (!flagModel?.actions_summary) {
      try {
        const response = await ajax(`/t/${this.topic.id}.json`);
        flagModel = EmberObject.create(response);
      } catch (error) {
        popupAjaxError(error);
        return;
      }
    } else {
      flagModel = EmberObject.create(flagModel);
    }

    this.modal.show(FlagModal, {
      model: {
        flagTarget: new TopicFlag(),
        flagModel,
        setHidden: () => {},
      },
    });
  }

  closeOverflowMenus() {
    this.isCompactOverflowOpen = false;
    this.#compactOverflowMenu?.close?.({ focusTrigger: false });
  }

  @action
  overflowShare(event) {
    this.copyTopicLink(event);
    this.closeOverflowMenus();
  }

  @action
  overflowSave(event) {
    this.toggleSave(event);
    this.closeOverflowMenus();
  }

  @action
  overflowReport(event) {
    this.reportTopic(event);
    this.closeOverflowMenus();
  }

  @action
  registerCompactOverflowMenu(menu) {
    this.#compactOverflowMenu = menu;
  }

  @action
  handleCompactOverflowShow() {
    this.isCompactOverflowOpen = true;
    this.#announceCompactOverflow();
  }

  @action
  handleCompactOverflowClose() {
    this.isCompactOverflowOpen = false;
  }

  @action
  handleCardClick(event) {
    if (wantsNewWindow(event)) {
      return;
    }

    const target = event.target;
    const isInteractive = target.closest(
      'a, button, [role="button"], .topic-vote-button, .topic-votes'
    );

    if (!isInteractive) {
      event.preventDefault();
      DiscourseURL.routeTo(this.firstPostUrl);
    }
  }

  @action
  handleCompactClick(event) {
    if (wantsNewWindow(event)) {
      return;
    }

    const target = event.target;
    const isInteractive = target.closest(
      'a, button, [role="button"], .topic-vote-button, .topic-votes, .d-menu'
    );

    if (!isInteractive) {
      event.preventDefault();
      DiscourseURL.routeTo(this.firstPostUrl);
    }
  }

  @action
  handleTileClick(event) {
    if (wantsNewWindow(event)) {
      return;
    }

    const target = event.target;
    const isInteractive = target.closest(
      'a, button, [role="button"], .topic-vote-button, .topic-votes, .d-menu'
    );

    if (!isInteractive) {
      event.preventDefault();
      DiscourseURL.routeTo(this.firstPostUrl);
    }
  }

  <template>
    {{#if this.topicThumbnails.displayCardStyle}}
      <CardView
        @topic={{this.topic}}
        @topicVoteControls={{this.topicVoteControlsComponent}}
        @firstPostUrl={{this.firstPostUrl}}
        @hasThumbnail={{this.hasThumbnail}}
        @fallbackSrc={{this.fallbackSrc}}
        @srcSet={{this.srcSet}}
        @width={{this.width}}
        @height={{this.height}}
        @placeholderIcon={{this.placeholderIcon}}
        @showAuthor={{this.showCardAuthor}}
        @showUserFeedback={{this.showUserFeedback}}
        @showCategory={{this.showCategory}}
        @isBookmarked={{this.isBookmarked}}
        @onClick={{this.handleCardClick}}
        @onShare={{this.copyTopicLink}}
        @onSave={{this.toggleSave}}
        @onReport={{this.reportTopic}}
        @onKeydown={{this.handleActionKeydown}}
      />
    {{else if this.topicThumbnails.displayCompactStyle}}
      <CompactView
        @topic={{this.topic}}
        @topicVoteControls={{this.topicVoteControlsComponent}}
        @firstPostUrl={{this.firstPostUrl}}
        @hasThumbnail={{this.hasThumbnail}}
        @fallbackSrc={{this.fallbackSrc}}
        @srcSet={{this.srcSet}}
        @width={{this.width}}
        @height={{this.height}}
        @placeholderIcon={{this.placeholderIcon}}
        @showAuthor={{this.showCompactAuthor}}
        @showUserFeedback={{this.showUserFeedback}}
        @showCategory={{this.showCategory}}
        @isBookmarked={{this.isBookmarked}}
        @commentsLabel={{this.commentsLabel}}
        @saveLabel={{this.saveLabel}}
        @removeSaveLabel={{this.removeSaveLabel}}
        @reportLabel={{this.reportLabel}}
        @overflowIdentifier={{this.compactOverflowIdentifier}}
        @onClick={{this.handleCompactClick}}
        @onShare={{this.copyTopicLink}}
        @onSave={{this.toggleSave}}
        @onReport={{this.reportTopic}}
        @onKeydown={{this.handleActionKeydown}}
        @onOverflowShare={{this.overflowShare}}
        @onOverflowSave={{this.overflowSave}}
        @onOverflowReport={{this.overflowReport}}
        @onRegisterOverflowMenu={{this.registerCompactOverflowMenu}}
        @onOverflowShow={{this.handleCompactOverflowShow}}
        @onOverflowClose={{this.handleCompactOverflowClose}}
      />
    {{else if this.topicThumbnails.displayTileStyle}}
      <TileView
        @topic={{this.topic}}
        @topicVoteControls={{this.topicVoteControlsComponent}}
        @firstPostUrl={{this.firstPostUrl}}
        @hasThumbnail={{this.hasThumbnail}}
        @fallbackSrc={{this.fallbackSrc}}
        @srcSet={{this.srcSet}}
        @width={{this.width}}
        @height={{this.height}}
        @placeholderIcon={{this.placeholderIcon}}
        @showAuthor={{this.showTileAuthor}}
        @showUserFeedback={{this.showUserFeedback}}
        @showCategory={{this.showCategory}}
        @isBookmarked={{this.isBookmarked}}
        @commentsLabel={{this.commentsLabel}}
        @saveLabel={{this.saveLabel}}
        @removeSaveLabel={{this.removeSaveLabel}}
        @reportLabel={{this.reportLabel}}
        @overflowIdentifier={{this.tileOverflowIdentifier}}
        @onClick={{this.handleTileClick}}
        @onShare={{this.copyTopicLink}}
        @onSave={{this.toggleSave}}
        @onReport={{this.reportTopic}}
        @onKeydown={{this.handleActionKeydown}}
        @onOverflowShare={{this.overflowShare}}
        @onOverflowSave={{this.overflowSave}}
        @onOverflowReport={{this.overflowReport}}
        @onRegisterOverflowMenu={{this.registerCompactOverflowMenu}}
        @onOverflowShow={{this.handleCompactOverflowShow}}
        @onOverflowClose={{this.handleCompactOverflowClose}}
      />
    {{/if}}
  </template>
}
