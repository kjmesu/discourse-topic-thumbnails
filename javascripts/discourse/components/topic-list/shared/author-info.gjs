import Component from "@glimmer/component";
import UserInfo from "discourse/components/user-info";
import categoryLink from "discourse/helpers/category-link";
import InlineUserFeedback from "../../inline-user-feedback";
import formatDateAlwaysRelative from "../../../helpers/format-date-always-relative";

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
          {{formatDateAlwaysRelative @topic.createdAt}}
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
