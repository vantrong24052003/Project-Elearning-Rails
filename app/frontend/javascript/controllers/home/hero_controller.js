import { Controller } from "@hotwired/stimulus";
import { animate } from "framer-motion";

export default class extends Controller {
  static targets = ["dot", "heading", "paragraph", "button", "image"];

  connect() {
    // Initialize dot animations
    this.animateDots();

    // Text and image animations
    this.animateContent();
  }

  animateDots() {
    if (!this.hasDotTarget) return;

    this.dotTargets.forEach(dot => {
      const duration = Math.random() * 5 + 5; // 5-10 seconds
      const startX = Math.random() * window.innerWidth;
      const startY = Math.random() * window.innerHeight;
      const endX = Math.random() * window.innerWidth;
      const endY = Math.random() * window.innerHeight;

      // Create animation using framer-motion
      animate(dot,
        [
          { x: startX, y: startY, scale: 0, opacity: 0 },
          { x: (startX + endX)/2, y: (startY + endY)/2, scale: 1, opacity: 0.5 },
          { x: endX, y: endY, scale: 0, opacity: 0 }
        ],
        {
          duration: duration,
          repeat: Infinity,
          ease: "linear"
        }
      );
    });
  }

  animateContent() {
    // Animate headings with staggered delay
    if (this.hasHeadingTarget) {
      this.headingTargets.forEach((heading, index) => {
        animate(heading,
          { opacity: [0, 1], y: [20, 0] },
          {
            duration: 0.6,
            delay: index * 0.2,
            ease: "easeOut"
          }
        );
      });
    }

    // Animate paragraph
    if (this.hasParagraphTarget) {
      animate(this.paragraphTarget,
        { opacity: [0, 1], y: [20, 0] },
        {
          duration: 0.6,
          delay: 0.4,
          ease: "easeOut"
        }
      );
    }

    // Animate buttons with staggered delay
    if (this.hasButtonTarget) {
      this.buttonTargets.forEach((button, index) => {
        animate(button,
          { opacity: [0, 1], x: [-20, 0] },
          {
            duration: 0.5,
            delay: 0.6 + (index * 0.15),
            ease: "easeOut"
          }
        );
      });
    }

    // Animate image
    if (this.hasImageTarget) {
      animate(this.imageTarget,
        { opacity: [0, 1], scale: [0.9, 1] },
        {
          duration: 0.8,
          delay: 0.3,
          ease: [0.175, 0.885, 0.32, 1.275] // Spring-like easing
        }
      );
    }
  }
}
