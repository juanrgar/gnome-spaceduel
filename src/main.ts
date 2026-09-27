import { Game } from './game/Game.js';

const canvas = document.querySelector<HTMLCanvasElement>('#game');
const statusText = document.querySelector<HTMLElement>('#status');
const score1 = document.querySelector<HTMLElement>('#score1');
const score2 = document.querySelector<HTMLElement>('#score2');

if (!canvas || !statusText || !score1 || !score2) {
  throw new Error('Game UI elements not found.');
}

const game = new Game(canvas, statusText, score1, score2);

window.addEventListener('keydown', (event) => {
  if (event.code === 'Space') {
    event.preventDefault();
    game.start();
  }

  if (event.code === 'KeyP') {
    game.togglePause();
  }
});

function loop(timestamp: number): void {
  game.update(timestamp);
  requestAnimationFrame(loop);
}

requestAnimationFrame(loop);
