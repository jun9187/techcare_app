const header = document.querySelector("[data-header]");
const nav = document.querySelector("[data-nav]");
const navToggle = document.querySelector("[data-nav-toggle]");
const navLinks = [...document.querySelectorAll(".site-nav a[href^='#']")];

function setMenu(open) {
  nav?.classList.toggle("is-open", open);
  navToggle?.setAttribute("aria-expanded", String(open));
  navToggle?.setAttribute("aria-label", open ? "Close navigation" : "Open navigation");
  document.body.classList.toggle("nav-open", open);
}

navToggle?.addEventListener("click", () => {
  setMenu(navToggle.getAttribute("aria-expanded") !== "true");
});

navLinks.forEach((link) => link.addEventListener("click", () => setMenu(false)));

document.addEventListener("keydown", (event) => {
  if (event.key === "Escape") setMenu(false);
});

function updateHeader() {
  header?.classList.toggle("is-scrolled", window.scrollY > 20);
}

updateHeader();
window.addEventListener("scroll", updateHeader, { passive: true });

const revealObserver = new IntersectionObserver(
  (entries, observer) => {
    entries.forEach((entry) => {
      if (!entry.isIntersecting) return;
      entry.target.classList.add("is-visible");
      observer.unobserve(entry.target);
    });
  },
  { threshold: 0.12 },
);

document.querySelectorAll(".reveal").forEach((element) => revealObserver.observe(element));

const sections = [...document.querySelectorAll("main section[id]")];
const sectionObserver = new IntersectionObserver(
  (entries) => {
    entries.forEach((entry) => {
      if (!entry.isIntersecting) return;
      navLinks.forEach((link) => {
        link.classList.toggle("is-active", link.hash === `#${entry.target.id}`);
      });
    });
  },
  { rootMargin: "-35% 0px -58%", threshold: 0 },
);

sections.forEach((section) => sectionObserver.observe(section));

const gallery = document.querySelector("[data-gallery]");
const galleryPrevious = document.querySelector("[data-gallery-prev]");
const galleryNext = document.querySelector("[data-gallery-next]");

function scrollGallery(direction) {
  const card = gallery?.querySelector(".shot-card");
  if (!gallery || !card) return;
  const gap = Number.parseFloat(getComputedStyle(gallery).gap) || 24;
  gallery.scrollBy({ left: direction * (card.offsetWidth + gap), behavior: "smooth" });
}

galleryPrevious?.addEventListener("click", () => scrollGallery(-1));
galleryNext?.addEventListener("click", () => scrollGallery(1));

document.querySelectorAll("[data-year]").forEach((element) => {
  element.textContent = new Date().getFullYear();
});

document.querySelectorAll("[data-placeholder-link]").forEach((link) => {
  link.addEventListener("click", (event) => event.preventDefault());
});
