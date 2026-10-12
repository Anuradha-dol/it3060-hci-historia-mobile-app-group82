{{flutter_js}}
{{flutter_build_config}}

// Flutter serves these SDK assets in debug mode and includes them in web builds.
// Resolve against the base href so deployments under a subdirectory also work.
// Avoid requiring a successful Google CDN download before the first frame.
_flutter.loader.load({
  config: {
    canvasKitBaseUrl: new URL('canvaskit/', document.baseURI).href,
  },
});
