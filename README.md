# Discourse Watch Category Button

Theme component that turns a marker span in posts into a “Watch this category” button. Clicking it sets the **current user’s** category notification level to Watching.

## How it works

### Post markup (sanitizer-safe)
Use a single data attribute. The **span text becomes the button label**:

```
<span data-watch-category="3">Watch this category</span>
```

- `data-watch-category` value = category ID
- inner text = button label (defaults to “Watch this category” if empty)

### Who can create buttons
Only posts **authored by users in the allowlist** are transformed into buttons. All users can see and click the rendered buttons.

### What happens on click
- POST `/category/{id}/notifications` with `notification_level=3`
- Button text updates to “Watching ✓”
- Category page header will update on next visit without a full refresh

## Files
- [javascripts/discourse/api-initializers/theme-initializer.gjs](javascripts/discourse/api-initializers/theme-initializer.gjs)
- [common/common.scss](common/common.scss)

## Notes
- Requires an explicit user click (no silent changes).
- No API keys are used; it relies on the logged-in session.
- To allow other groups, update the `ALLOWED_GROUPS` list in the initializer.
