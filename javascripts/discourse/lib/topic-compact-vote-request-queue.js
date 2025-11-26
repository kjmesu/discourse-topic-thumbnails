import { later } from "@ember/runloop";

const MAX_CONCURRENT = 3;
const REQUEST_DELAY_MS = 200;

const pending = [];
const inflight = new Map();
let active = 0;

function processQueue() {
  if (active >= MAX_CONCURRENT || pending.length === 0) {
    return;
  }

  const job = pending.shift();
  active++;

  job
    .execute()
    .catch(() => {})
    .finally(() => {
      active--;
      later(processQueue, REQUEST_DELAY_MS);
    });
}

export function queueVoteRequest(key, task) {
  if (inflight.has(key)) {
    return inflight.get(key);
  }

  const promise = new Promise((resolve, reject) => {
    pending.push({
      execute: async () => {
        try {
          const result = await task();
          resolve(result);
          return result;
        } catch (error) {
          reject(error);
          throw error;
        } finally {
          inflight.delete(key);
        }
      },
    });

    processQueue();
  });

  inflight.set(key, promise);

  return promise;
}
