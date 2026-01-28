# Discourse Watch Category Button

Theme component that turns a marker span in posts into a “Watch this category” button. Clicking it sets the **current user’s** category notification level to Watching.

## How it works

### Put a 'Watch this category' button in a post

Use this markup inside a post to create the button:
```
<span data-watch-category="3">Watch the category with ID 3</span>
```
The user's notification level for category ID 3 will be set to Watching.


To target the **current post’s category**, use one of these:

```
<span data-watch-category="current">Watch this category</span>
```

```
<span data-watch-category-current>Watch this category</span>
```

- `data-watch-category` value = category ID (or `current`/`this`/empty)
- `data-watch-category-current` = use current post category
- inner text = button label (defaults to “Watch this category” if empty)

### Who can create buttons

Only posts **authored by users in the allowlist** are transformed into buttons. By default, `staff` is allowed. All users can see and click the rendered buttons.

### What happens on click

- POST `/category/{id}/notifications` with `notification_level=3`
- Button text updates to “Watching ✓”
- If you’re on the category page, the header button updates immediately; otherwise it will sync on the next visit without a full refresh

### UX details

- Button disables and shows “Updating…” while the request is in flight
- On error, the original text is restored and a Discourse AJAX error is shown

## Files

- [javascripts/discourse/api-initializers/theme-initializer.gjs](javascripts/discourse/api-initializers/theme-initializer.gjs)
- [common/common.scss](common/common.scss)

## Notes

- Requires an explicit user click (no silent changes).
- No API keys are used; it relies on the logged-in session.
- To allow other groups, update the `ALLOWED_GROUPS` list in the initializer.
