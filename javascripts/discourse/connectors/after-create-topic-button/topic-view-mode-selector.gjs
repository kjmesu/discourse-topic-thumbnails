import Component from "@glimmer/component";
import { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";
import { service } from "@ember/service";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import willDestroy from "@ember/render-modifiers/modifiers/will-destroy";
import concatClass from "discourse/helpers/concat-class";
import icon from "discourse/helpers/d-icon";
import { eq } from "discourse/truth-helpers";
import I18n from "I18n";
import { themePrefix } from "virtual:theme";

export default class TopicViewModeSelector extends Component {
  @service topicThumbnails;

  @tracked isOpen = false;
  wrapperElement = null;

  get showSelector() {
    return (
      this.topicThumbnails.enabledForRoute &&
      this.topicThumbnails.enabledForDevice &&
      this.topicThumbnails.availableViewModes.length > 1
    );
  }

  get buttonLabel() {
    return I18n.t(themePrefix("topic_thumbnails.view_selector.label"));
  }

  get modes() {
    return this.topicThumbnails.availableViewModes.map((mode) => ({
      value: mode,
      label: I18n.t(themePrefix(`topic_thumbnails.view_modes.${mode}`), {
        defaultValue: mode,
      }),
    }));
  }

  get selectedMode() {
    return this.topicThumbnails.manualDisplayMode || null;
  }

  @action
  toggleMenu(event) {
    event?.stopPropagation();
    this.isOpen = !this.isOpen;
  }

  @action
  closeMenu() {
    this.isOpen = false;
  }

  @action
  selectMode(mode) {
    const normalized = this.selectedMode === mode ? null : mode;
    this.topicThumbnails.setManualDisplayMode(normalized);
    this.closeMenu();
  }

  @action
  registerWrapper(element) {
    this.wrapperElement = element;
    document.addEventListener("click", this.handleDocumentClick, true);
  }

  @action
  cleanupWrapper() {
    document.removeEventListener("click", this.handleDocumentClick, true);
    this.wrapperElement = null;
  }

  @action
  handleDocumentClick(event) {
    if (this.wrapperElement?.contains(event.target)) {
      return;
    }
    this.closeMenu();
  }

  <template>
    {{#if this.showSelector}}
      <div
        class={{concatClass
          "topic-view-mode-selector"
          (if this.isOpen "is-open")
        }}
        {{didInsert this.registerWrapper}}
        {{willDestroy this.cleanupWrapper}}
      >
        <button
          type="button"
          class="btn btn-default topic-view-mode-selector__button"
          aria-haspopup="listbox"
          aria-expanded={{if this.isOpen "true" "false"}}
          aria-label={{this.buttonLabel}}
          {{on "click" this.toggleMenu}}
        >
          <span class="topic-view-mode-selector__icon">
            {{icon "list"}}
          </span>
          <span class="topic-view-mode-selector__caret">
            {{icon (if this.isOpen "caret-up" "caret-down")}}
          </span>
        </button>

        <div
          class="topic-view-mode-selector__menu"
          role="listbox"
          aria-label={{this.buttonLabel}}
        >
          {{#each this.modes as |mode|}}
            <button
              type="button"
              class={{concatClass
                "topic-view-mode-selector__menu-item"
                (if (eq this.selectedMode mode.value) "is-selected")
              }}
              data-value={{mode.value}}
              {{on "click" (fn this.selectMode mode.value)}}
            >
              {{mode.label}}
            </button>
          {{/each}}
        </div>
      </div>
    {{/if}}
  </template>
}
