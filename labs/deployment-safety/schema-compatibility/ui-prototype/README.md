# Schema Compatibility Replay UI prototype

This prototype has three deliberately different read-only layouts for the first OpsProof module. Each replays representative unsafe rename, safe expand, and safe rollback results. It does not connect to a cluster or show measured run output.

Run locally:

```sh
npm run dev
```

The replay opens on `http://localhost:4173`.

Use the header to switch scenarios. The controls above the page start, pause, and reset the replay. Switch layouts with the floating control, the left and right arrow keys, or a shareable URL:

- `?variant=control`: deployment control room; recommended for the Lab
- `?variant=traffic`: request-by-request flow
- `?variant=brief`: incident decision brief

The selected direction will replace representative data with a run artifact written by the Schema Compatibility Lab. Raw logs remain supporting evidence, not the primary interface.

Validate the prototype:

```sh
npm run build
```
