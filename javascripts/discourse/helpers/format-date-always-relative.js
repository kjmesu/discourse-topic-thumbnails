import { htmlSafe } from "@ember/template";
import { i18n } from "discourse-i18n";
import { themePrefix } from "virtual:theme";

export default function formatDateAlwaysRelative(date) {
  if (!date) {
    return "";
  }

  const now = new Date();
  const targetDate = new Date(date);
  const distanceInSeconds = Math.round((now - targetDate) / 1000);
  const distanceInMinutes = Math.max(Math.round(distanceInSeconds / 60), 1);

  let formatted;

  if (distanceInMinutes <= 44) {
    formatted = i18n(themePrefix("dates.x_minutes"), {
      count: distanceInMinutes,
    });
  } else if (distanceInMinutes <= 89) {
    formatted = i18n(themePrefix("dates.x_hours"), { count: 1 });
  } else if (distanceInMinutes <= 1409) {
    formatted = i18n(themePrefix("dates.x_hours"), {
      count: Math.round(distanceInMinutes / 60),
    });
  } else if (distanceInMinutes <= 2519) {
    formatted = i18n(themePrefix("dates.x_days"), { count: 1 });
  } else if (distanceInMinutes <= 43199) {
    formatted = i18n(themePrefix("dates.x_days"), {
      count: Math.round(distanceInMinutes / 1440),
    });
  } else if (distanceInMinutes <= 525599) {
    formatted = i18n(themePrefix("dates.x_months"), {
      count: Math.round(distanceInMinutes / 43200),
    });
  } else {
    formatted = i18n(themePrefix("dates.x_years"), {
      count: Math.round(distanceInMinutes / 525600),
    });
  }

  return htmlSafe(formatted);
}
