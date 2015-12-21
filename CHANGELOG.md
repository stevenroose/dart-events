Changelog
=========

# 0.1.2

- Added `events_nomirrors.dart` with an implementation that does not have the inheritance-based event matching but does not import mirrors.
- Updated dependency of `LRUMap` to a version that does not need mirrors.

# 0.1.1+1

Also use the stream cache for `.once()`` listeners.

# 0.1.1

Added stream caching to reduce CPU cost when multiple subscribers subscribe to the same event type.

# 0.1.0

Initial version