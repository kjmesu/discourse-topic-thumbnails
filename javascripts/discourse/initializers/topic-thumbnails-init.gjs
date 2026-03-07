import { readOnly } from "@ember/object/computed";
import { service } from "@ember/service";
import { apiInitializer } from "discourse/lib/api";
import TopicListThumbnail from "../components/topic-list-thumbnail";

export default apiInitializer((api) => {
  const ttService = api.container.lookup("service:topic-thumbnails");

  api.registerValueTransformer("topic-list-class", ({ value }) => {
    if (ttService.displayCompactStyle) {
      value.push("topic-thumbnails-compact");
    } else if (ttService.displayCardStyle) {
      value.push("topic-thumbnails-card-style");
    }
    return value;
  });

  api.registerValueTransformer("topic-list-columns", ({ value: columns }) => {
    return columns;
  });

  api.renderInOutlet(
    "topic-list-before-link",
    <template>
      {{#if ttService.displayCompactStyle}}
        <TopicListThumbnail @topic={{@outletArgs.topic}} />
      {{else if ttService.displayCardStyle}}
        <TopicListThumbnail @topic={{@outletArgs.topic}} />
      {{/if}}
    </template>
  );

  api.registerValueTransformer("topic-list-item-mobile-layout", ({ value }) => {
    if (ttService.enabledForRoute) {
      // Force the desktop layout
      return false;
    }
    return value;
  });

  const siteSettings = api.container.lookup("service:site-settings");
  if (settings.docs_thumbnail_mode !== "none" && siteSettings.docs_enabled) {
    api.modifyClass("component:docs-topic-list", {
      pluginId: "topic-thumbnails",
      topicThumbnailsService: service("topic-thumbnails"),
      classNameBindings: [
        "isCompactStyle:topic-thumbnails-compact",
        "isCardStyle:topic-thumbnails-card-style",
      ],
      isCompactStyle: readOnly("topicThumbnailsService.displayCompactStyle"),
      isCardStyle: readOnly("topicThumbnailsService.displayCardStyle"),
    });
  }
});
