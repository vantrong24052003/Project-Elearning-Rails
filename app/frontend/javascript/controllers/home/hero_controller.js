import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["dot", "dotsContainer"];

  connect() {
    if (this.hasDotTarget) {
      this.animateDots();
    } else if (this.hasDotsContainerTarget) {
      this.createDots();
    }
  }

  animateDots() {
    this.dotTargets.forEach(dot => {
      this.animateSingleDot(dot);
    });
  }

  createDots() {
    const container = this.dotsContainerTarget;
    const containerRect = container.getBoundingClientRect();
    const containerWidth = containerRect.width;
    const containerHeight = containerRect.height;

    for (let i = 0; i < 30; i++) {
      const dot = document.createElement('div');

      const size = Math.random() * 4 + 2;

      dot.className = 'absolute rounded-full';
      dot.style.width = `${size}px`;
      dot.style.height = `${size}px`;

      const colors = [
        'bg-purple-400', 'bg-pink-400', 'bg-indigo-400',
        'bg-purple-500', 'bg-pink-500', 'bg-indigo-500'
      ];
      dot.classList.add(colors[Math.floor(Math.random() * colors.length)]);

      const x = Math.random() * containerWidth;
      const y = Math.random() * containerHeight;
      dot.style.left = `${x}px`;
      dot.style.top = `${y}px`;

      dot.style.opacity = Math.min(0.1 + size / 10, 0.7);

      container.appendChild(dot);

      setTimeout(() => {
        this.animateSingleDot(dot, containerWidth, containerHeight);
      }, Math.random() * 1000);
    }
  }

  animateSingleDot(dot, maxWidth = window.innerWidth, maxHeight = window.innerHeight) {
    const animate = () => {
      const duration = Math.random() * 15000 + 15000;

      const newX = Math.random() * maxWidth;
      const newY = Math.random() * maxHeight;

      dot.style.transition = `transform ${duration}ms cubic-bezier(0.4, 0, 0.2, 1)`;
      dot.style.transform = `translate(${newX - parseFloat(dot.style.left)}px, ${newY - parseFloat(dot.style.top)}px)`;

      setTimeout(() => {
        const computedStyle = window.getComputedStyle(dot);
        const matrix = new DOMMatrix(computedStyle.transform);

        dot.style.transform = 'translate(0, 0)';
        dot.style.left = `${parseFloat(dot.style.left) + matrix.m41}px`;
        dot.style.top = `${parseFloat(dot.style.top) + matrix.m42}px`;

        animate();
      }, duration);
    };

    animate();
  }
}
