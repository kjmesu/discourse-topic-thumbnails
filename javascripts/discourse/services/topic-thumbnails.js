import { tracked, cached } from "@glimmer/tracking";
import { dependentKeyCompat } from "@ember/object/compat";
import Service, { service } from "@ember/service";
import discourseComputed from "discourse/lib/decorators";
import Site from "discourse/models/site";

const STORAGE_KEY = "topic-thumbnails-manual-modes";

const compactCategories = settings.compact_categories
  .split("|")
  .map((id) => parseInt(id, 10));

const cardCategories = settings.card_categories
  .split("|")
  .map((id) => parseInt(id, 10));

const compactTags = settings.compact_tags.split("|");
const cardTags = settings.card_tags.split("|");

const enabledCategories = settings.enabled_categories
  .split("|")
  .map((id) => parseInt(id, 10))
  .filter((id) => !isNaN(id));

const categoryPlaceholderMap = (() => {
  const map = {};
  if (!settings.category_placeholder_icons) {
    return map;
  }

  settings.category_placeholder_icons.split("|").forEach((pair) => {
    const parts = pair.split(":");
    if (parts.length === 2) {
      const categoryId = parseInt(parts[0].trim(), 10);
      const iconName = parts[1].trim();
      if (!isNaN(categoryId) && iconName) {
        map[categoryId] = iconName;
      }
    }
  });

  return map;
})();

export default class TopicThumbnailService extends Service {
  @service router;
  @service discovery;
  @service keyValueStore;

  @tracked manualSelectionsVersion = 0;

  manualSelections = this.#loadManualSelections();

  @cached
  get enabledCategoriesList() {
    return enabledCategories;
  }

  getPlaceholderIconForCategory(categoryId) {
    return categoryPlaceholderMap[categoryId];
  }

  @dependentKeyCompat
  get isTopicListRoute() {
    return this.discovery.onDiscoveryRoute;
  }

  @cached
  get isTopicRoute() {
    return this.router.currentRouteName.match(/^topic\./);
  }

  @cached
  get isDocsRoute() {
    return this.router.currentRouteName.match(/^docs\./);
  }

  @dependentKeyCompat
  get viewingCategoryId() {
    return this.discovery.category?.id;
  }

  @dependentKeyCompat
  get viewingTagName() {
    return this.discovery.tag?.name;
  }

  @dependentKeyCompat
  get isViewingCategory() {
    return !!this.viewingCategoryId;
  }

  @dependentKeyCompat
  get currentContextKey() {
    return "global";
  }

  @discourseComputed("manualSelectionsVersion", "currentContextKey")
  manualDisplayMode() {
    if (!this.currentContextKey) {
      return null;
    }
    return this.manualSelections?.[this.currentContextKey] || null;
  }

  @discourseComputed(
    "viewingCategoryId",
    "viewingTagName",
    "router.currentRoute.metadata.customThumbnailMode",
    "isTopicListRoute",
    "isTopicRoute",
    "isDocsRoute",
    "manualDisplayMode"
  )
  displayMode(
    viewingCategoryId,
    viewingTagName,
    customThumbnailMode,
    isTopicListRoute,
    isTopicRoute,
    isDocsRoute
  ) {
    if (customThumbnailMode) {
      return customThumbnailMode;
    }
    if (this.manualDisplayMode) {
      if (isTopicListRoute || settings.enable_outside_topic_lists) {
        return this.manualDisplayMode;
      }
    }
    if (cardCategories.includes(viewingCategoryId)) {
      return "card-style";
    } else if (compactCategories.includes(viewingCategoryId)) {
      return "compact-style";
    } else if (cardTags.includes(viewingTagName)) {
      return "card-style";
    } else if (compactTags.includes(viewingTagName)) {
      return "compact-style";
    } else if (isTopicListRoute) {
      return settings.default_thumbnail_mode;
    } else if (settings.enable_outside_topic_lists) {
      if (isTopicRoute && settings.suggested_topics_mode) {
        return settings.suggested_topics_mode;
      } else if (isDocsRoute) {
        return settings.docs_thumbnail_mode;
      } else {
        return settings.default_thumbnail_mode;
      }
    } else {
      return "none";
    }
  }

  @discourseComputed("displayMode")
  enabledForRoute(displayMode) {
    return displayMode !== "none";
  }

  @discourseComputed()
  enabledForDevice() {
    return Site.current().mobileView ? settings.mobile_thumbnails : true;
  }

  @discourseComputed("enabledForRoute", "enabledForDevice")
  shouldDisplay(enabledForRoute, enabledForDevice) {
    return enabledForRoute && enabledForDevice;
  }

  @discourseComputed("shouldDisplay", "displayMode")
  displayCompactStyle(shouldDisplay, displayMode) {
    return shouldDisplay && displayMode === "compact-style";
  }

  @discourseComputed("shouldDisplay", "displayMode")
  displayCardStyle(shouldDisplay, displayMode) {
    return shouldDisplay && displayMode === "card-style";
  }

  get availableViewModes() {
    return ["compact-style", "card-style"];
  }

  setManualDisplayMode(mode) {
    const contextKey = this.currentContextKey;
    if (!contextKey) {
      return;
    }
    const normalizedMode = mode || null;
    const existing = this.manualSelections?.[contextKey] || null;
    if (existing === normalizedMode) {
      return;
    }

    if (normalizedMode) {
      this.manualSelections = {
        ...this.manualSelections,
        [contextKey]: normalizedMode,
      };
    } else if (this.manualSelections?.[contextKey]) {
      const updated = { ...this.manualSelections };
      delete updated[contextKey];
      this.manualSelections = updated;
    }
    this.manualSelectionsVersion++;
    this.#persistManualSelections();

    if (typeof this.router?.refresh === "function") {
      this.router.refresh();
    }
  }

  #persistManualSelections() {
    try {
      this.keyValueStore.setItem(STORAGE_KEY, this.manualSelections || {});
    } catch (e) {
      // eslint-disable-next-line no-console
      console.warn("Failed to persist topic thumbnail manual selection", e);
    }
  }

  #loadManualSelections() {
    try {
      const data = this.keyValueStore.getItem(STORAGE_KEY);
      if (data && typeof data === "object") {
        return data;
      }
    } catch (e) {
      // eslint-disable-next-line no-console
      console.warn("Failed to load topic thumbnail manual selections", e);
    }
    return {};
  }
}
