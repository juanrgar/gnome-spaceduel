import { Bullet, Ship, Sprite, collides } from './entities';
import { InputManager } from './input';
import { clamp } from './math';

export type GameStatus = 'new-game' | 'playing' | 'finished-round' | 'new-round';

export class Game {
  private readonly canvas: HTMLCanvasElement;
  private readonly ctx: CanvasRenderingContext2D;
  private readonly input: InputManager;
  private readonly sun: Sprite;
  private readonly ships: Ship[];
  private readonly bullets: Bullet[];
  private readonly gameWidth: number;
  private readonly gameHeight: number;

  private status: GameStatus = 'new-game';
  private started = false;
  private paused = false;
  private lastTimestamp = 0;
  private gameSpeed = 1;
  private sunGravity = 0.08;
  private bulletDamage = 0.45;
  private baseBulletCount = 10;
  private round = 1;

  private readonly statusText: HTMLElement;
  private readonly score1: HTMLElement;
  private readonly score2: HTMLElement;

  constructor(canvas: HTMLCanvasElement, statusText: HTMLElement, score1: HTMLElement, score2: HTMLElement) {
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d')!;
    this.input = new InputManager();
    this.gameWidth = canvas.width;
    this.gameHeight = canvas.height;

    this.statusText = statusText;
    this.score1 = score1;
    this.score2 = score2;

    this.sun = new Sprite('sun', this.gameWidth / 2, this.gameHeight / 2, 30, '#ffb347');
    this.ships = [
      new Ship(this.gameWidth / 2, this.gameHeight / 4, '#7dd3fc'),
      new Ship(this.gameWidth / 2, (this.gameHeight * 3) / 4, '#f9a8d4'),
    ];
    this.bullets = [];

    this.resetShips();
    this.updateHud();
  }

  start(): void {
    if (this.status === 'new-game' || this.status === 'new-round') {
      this.started = true;
      this.paused = false;
      this.status = 'playing';
      this.statusText.textContent = '';
    }
  }

  togglePause(): void {
    if (!this.started) return;
    this.paused = !this.paused;
  }

  update(timestamp: number): void {
    const delta = Math.min((timestamp - this.lastTimestamp) / 16.6667 || 1, 3);
    this.lastTimestamp = timestamp;

    if (!this.started || this.paused) {
      this.render();
      return;
    }

    this.updatePhysics(delta);
    this.resolveCollisions();
    this.render();
  }

  render(): void {
    this.ctx.clearRect(0, 0, this.gameWidth, this.gameHeight);
    this.ctx.fillStyle = '#060d1a';
    this.ctx.fillRect(0, 0, this.gameWidth, this.gameHeight);

    this.sun.draw(this.ctx);

    for (const ship of this.ships) {
      ship.draw(this.ctx);
    }

    for (const bullet of this.bullets) {
      bullet.draw(this.ctx);
    }
  }

  private updatePhysics(delta: number): void {
    const shipInputs = [this.input.getPlayerState(0), this.input.getPlayerState(1)];

    for (let i = 0; i < this.ships.length; i++) {
      const ship = this.ships[i];
      const input = shipInputs[i];

      const dx = ship.x - this.sun.x;
      const dy = ship.y - this.sun.y;
      const dist = clamp(Math.hypot(dx, dy), 1, Number.MAX_VALUE);
      const nx = dx / dist;
      const ny = dy / dist;
      const gravity = this.sunGravity * this.gameSpeed;

      ship.velocityX -= (nx * gravity) / (dist * 0.12);
      ship.velocityY -= (ny * gravity) / (dist * 0.12);

      if (input.accelerate) ship.accelerate();
      if (input.rotateRight) ship.rotateRight();
      if (input.rotateLeft) ship.rotateLeft();

      if (input.fire && ship.firedBullets < ship.availableBullets) {
        const bullet = new Bullet(ship.x, ship.y, i === 0 ? '#d4f7ff' : '#ffd6ef');
        const rad = (ship.angle * Math.PI) / 180;
        bullet.velocityX = ship.velocityX + Math.cos(rad) * 4.2;
        bullet.velocityY = ship.velocityY + Math.sin(rad) * 4.2;
        bullet.x = ship.x + Math.cos(rad) * (ship.radius + 10);
        bullet.y = ship.y + Math.sin(rad) * (ship.radius + 10);
        bullet.life = 1.5;
        ship.fire();
        this.bullets.push(bullet);
      }

      ship.velocityX *= 0.995;
      ship.velocityY *= 0.995;
      ship.update(this.gameWidth, this.gameHeight);
    }

    for (const bullet of this.bullets) {
      bullet.applyGravity(this.sun, this.sunGravity * 18);
      bullet.update(this.gameWidth, this.gameHeight);
      bullet.life -= 0.016 * delta;
    }

    for (let i = this.bullets.length - 1; i >= 0; i--) {
      if (this.bullets[i].life <= 0) {
        this.bullets.splice(i, 1);
      }
    }
  }

  private resolveCollisions(): void {
    for (const ship of this.ships) {
      if (collides(ship, this.sun)) {
        this.finishRound(ship);
        return;
      }
    }

    for (let i = 0; i < this.ships.length; i++) {
      for (let j = i + 1; j < this.ships.length; j++) {
        if (collides(this.ships[i], this.ships[j])) {
          this.finishRound(this.ships[i], this.ships[j]);
          return;
        }
      }
    }

    for (let i = this.bullets.length - 1; i >= 0; i--) {
      const bullet = this.bullets[i];

      for (const ship of this.ships) {
        if (collides(bullet, ship)) {
          this.bullets.splice(i, 1);
          const destroyed = ship.damage(this.bulletDamage);
          if (destroyed) {
            this.finishRound(ship);
            return;
          }
          break;
        }
      }

      if (collides(bullet, this.sun)) {
        this.bullets.splice(i, 1);
      }
    }
  }

  private finishRound(...losers: Ship[]): void {
    this.started = false;
    this.status = 'finished-round';

    if (losers.length === 2) {
      this.statusText.textContent = 'Even round';
    } else {
      const winnerIndex = this.ships.indexOf(losers[0]) === 0 ? 1 : 0;
      this.ships[winnerIndex].score += 1;
      this.statusText.textContent = `Player ${winnerIndex + 1} wins`;
    }

    this.updateHud();
    this.round += 1;
    setTimeout(() => {
      this.resetShips();
      this.status = 'new-round';
      this.statusText.textContent = 'Press SPACE to start next round';
    }, 1500);
  }

  private resetShips(): void {
    const startVelX = 1.8;
    const startVelY = 1.4;

    this.ships[0].reset(this.gameWidth / 2, this.gameHeight / 4, 0, startVelX, startVelY);
    this.ships[1].reset(this.gameWidth / 2, (this.gameHeight * 3) / 4, 180, -startVelX, -startVelY);
    this.ships[0].availableBullets = this.baseBulletCount;
    this.ships[1].availableBullets = this.baseBulletCount;

    this.bullets.length = 0;
  }

  private updateHud(): void {
    this.score1.textContent = String(this.ships[0].score);
    this.score2.textContent = String(this.ships[1].score);
  }

  handleKeyboard(): void {
    if (this.input.getPlayerState(0).accelerate) {
      // no-op handled by update loop
    }
  }
}
