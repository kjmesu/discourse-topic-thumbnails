import Component from "@glimmer/component";
import dIcon from "discourse/helpers/d-icon";

export default class ThumbnailImage extends Component {
  get hasThumbnail() {
    return this.args.thumbnails && this.args.thumbnails.length > 0;
  }

  <template>
    {{#if this.hasThumbnail}}
      <img
        class="background-thumbnail"
        src={{@fallbackSrc}}
        srcset={{@srcSet}}
        width={{@width}}
        height={{@height}}
        loading="lazy"
        decoding="async"
        alt=""
        aria-hidden="true"
      />
      <img
        class="main-thumbnail"
        src={{@fallbackSrc}}
        srcset={{@srcSet}}
        width={{@width}}
        height={{@height}}
        loading="lazy"
        decoding="async"
        alt=""
      />
    {{else}}
      <div class="thumbnail-placeholder">
        {{dIcon @placeholderIcon}}
      </div>
    {{/if}}
  </template>
}
