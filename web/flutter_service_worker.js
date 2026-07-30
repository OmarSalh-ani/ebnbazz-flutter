// One-shot cleanup for legacy Flutter PWA caches (app uses serviceWorkerSettings: null).
// Browsers with an old controlling worker fetch this file on update; activate clears caches.
'use strict';

self.addEventListener('install', function (event) {
  self.skipWaiting();
});

self.addEventListener('activate', function (event) {
  event.waitUntil(
    caches
      .keys()
      .then(function (names) {
        return Promise.all(
          names.map(function (name) {
            return caches.delete(name);
          }),
        );
      })
      .then(function () {
        return self.registration.unregister();
      }),
  );
});
