import { apiInitializer } from "discourse/lib/api";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

const WATCHING_LEVEL = 3;
const WATCHING_LEVEL_NAME = "watching";
const WATCH_CATEGORY_STORAGE_KEY = "watch-category-updated-id";
const ALLOWED_GROUPS = ["staff"];

const isPostAuthorAllowed = (post) => {
  if (!post?.user) return false;

  if (ALLOWED_GROUPS.includes("staff") && post.user.staff) {
    return true;
  }

  const groupNames = post.user.group_names || [];
  return ALLOWED_GROUPS.some((group) => groupNames.includes(group));
};

const updateCategoryHeaderNotificationButton = () => {
  const buttons = document.querySelectorAll(
    "button[class*=\"category-notifications-\"]"
  );
  if (!buttons.length) return;

  buttons.forEach((button) => {
    button.setAttribute("data-level-id", String(WATCHING_LEVEL));
    button.setAttribute("data-level-name", WATCHING_LEVEL_NAME);
    button.setAttribute("data-identifier", "notifications-tracking");
    button.setAttribute("title", "Watching");

    const label = button.querySelector(".d-button-label");
    if (label) {
      label.textContent = "Watching";
    }

    const icon = button.querySelector("svg use");
    if (icon) {
      icon.setAttribute("href", "#discourse-bell-exclamation");
    }

    const svg = button.querySelector("svg");
    if (svg) {
      svg.classList.remove("d-icon-d-muted", "d-icon-d-regular");
      svg.classList.add("d-icon-d-watching");
    }
  });
};

const syncCategoryPageNotificationState = (api, updatedId, attemptsLeft = 10) => {
  const categoryController = api.container.lookup("controller:category");
  const currentId = categoryController?.model?.id;

  if (!currentId) {
    if (attemptsLeft > 0) {
      setTimeout(
        () =>
          syncCategoryPageNotificationState(api, updatedId, attemptsLeft - 1),
        50
      );
    }
    return;
  }

  if (String(currentId) !== String(updatedId)) return;

  categoryController?.model?.set?.("notification_level", WATCHING_LEVEL);
  categoryController?.model?.set?.(
    "notification_level_name",
    WATCHING_LEVEL_NAME
  );

  setTimeout(updateCategoryHeaderNotificationButton, 0);
  sessionStorage.removeItem(WATCH_CATEGORY_STORAGE_KEY);
};

export default apiInitializer("1.8.0", (api) => {
  api.onPageChange(() => {
    const updatedId = sessionStorage.getItem(WATCH_CATEGORY_STORAGE_KEY);
    if (!updatedId) return;

    syncCategoryPageNotificationState(api, updatedId);
  });

  api.decorateCookedElement(
    (elem, helper) => {
      const post = helper?.getModel?.() || helper?.post;
      if (!isPostAuthorAllowed(post)) return;

      elem.querySelectorAll("[data-watch-category]").forEach((node) => {
        const attributeValue = node.getAttribute("data-watch-category");
        const shouldUseCurrentCategory = attributeValue === "current";
        const categoryId = shouldUseCurrentCategory
          ? post?.category_id ||
            post?.topic?.category_id ||
            post?.topic?.category?.id
          : attributeValue;
        if (!categoryId) return;

        const button = document.createElement("button");
        button.type = "button";
        button.className = "btn btn-primary watch-category-action";
        button.textContent = node.textContent?.trim() || "Watch this category";

        button.addEventListener("click", async () => {
          button.disabled = true;
          const oldText = button.textContent;
          button.textContent = "Updating…";

          try {
            await ajax(`/category/${categoryId}/notifications`, {
              type: "POST",
              data: { notification_level: WATCHING_LEVEL },
            });

            sessionStorage.setItem(
              WATCH_CATEGORY_STORAGE_KEY,
              String(categoryId)
            );

            const categoryController = api.container.lookup(
              "controller:category"
            );
            if (
              String(categoryController?.model?.id) === String(categoryId)
            ) {
              const model = categoryController.model;
              model?.set?.("notification_level", WATCHING_LEVEL);
              model?.set?.("notification_level_name", WATCHING_LEVEL_NAME);

              const router = api.container.lookup("router:main");
              router?.refresh?.();
              updateCategoryHeaderNotificationButton();
              setTimeout(updateCategoryHeaderNotificationButton, 0);
            }

            button.classList.remove("btn-primary");
            button.classList.add("btn-default");
            button.textContent = "Watching ✓";
          } catch (e) {
            button.disabled = false;
            button.textContent = oldText;
            popupAjaxError(e);
          }
        });

        node.replaceWith(button);
      });
    },
    { id: "watch-category-button" }
  );
});