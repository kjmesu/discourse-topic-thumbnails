import { htmlSafe } from "@ember/template";

export default function formatDateCompact(date) {
  if (!date) {
    return "";
  }

  const now = new Date();
  const targetDate = new Date(date);
  const distanceInSeconds = Math.round((now - targetDate) / 1000);
  const distanceInMinutes = Math.max(Math.round(distanceInSeconds / 60), 1);

  let formatted;

  if (distanceInMinutes <= 44) {
    formatted = `${distanceInMinutes}m`;
  } else if (distanceInMinutes <= 1409) {
    formatted = `${Math.round(distanceInMinutes / 60)}h`;
  } else if (distanceInMinutes <= 43199) {
    formatted = `${Math.round(distanceInMinutes / 1440)}d`;
  } else if (distanceInMinutes <= 525599) {
    formatted = `${Math.round(distanceInMinutes / 43200)}mo`;
  } else {
    formatted = `${Math.round(distanceInMinutes / 525600)}y`;
  }

  return htmlSafe(formatted);
}
