{{flutter_js}}
{{flutter_build_config}}

// Disable the PWA service worker on web. The app ships ~600 Quran page fonts (~100MB+);
// the default SW caches them aggressively and can cause Chrome out-of-memory errors.
_flutter.loader.load({
  serviceWorkerSettings: null,
  config: {
    // Use bundled canvaskit only — avoids a second 7MB download from gstatic
    // that can abort FontManifest.json on Firefox (NS_ERROR_NET_INTERRUPT).
    canvasKitBaseUrl: '/canvaskit/',
  },
});
