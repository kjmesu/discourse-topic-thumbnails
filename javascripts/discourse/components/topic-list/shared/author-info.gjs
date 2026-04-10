import Component from "@glimmer/component";
import UserInfo from "discourse/components/user-info";
import categoryLink from "discourse/helpers/category-link";
import InlineUserFeedback from "../../inline-user-feedback";
import formatDateAlwaysRelative from "../../../helpers/format-date-always-relative";
import formatDateCompact from "../../../helpers/format-date-compact";

export default class AuthorInfo extends Component {
  <template>
    <UserInfo
      @user={{@topic.creator}}
      @includeLink={{true}}
      @includeAvatar={{true}}
      @size="small"
      class={{@userClass}}
    />
    {{#if @showUserFeedback}}
      <InlineUserFeedback
        @shouldRender={{true}}
        @rating={{@topic.creator.average_rating}}
        @count={{@topic.creator.total_trade_count}}
      />
    {{/if}}
    {{#if @showActivity}}
      <span class={{@activityClass}}>
        <span class="topic-author__relative-date">
          {{#if @compactDate}}
            {{formatDateCompact @topic.createdAt}}
          {{else}}
            {{formatDateAlwaysRelative @topic.createdAt}}
          {{/if}}
        </span>
      </span>
    {{/if}}
    {{#if @showCategory}}
      <span class={{@categoryClass}}>
        {{categoryLink @topic.category}}
      </span>
    {{/if}}
  </template>
}
