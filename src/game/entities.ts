import { clamp, distance } from './math';

export type EntityKind = 'ship' | 'bullet' | 'sun';

export class Sprite {
  kind: EntityKind;
  x: number;
  y: number;
  radius: number;
  width: number;
  height: number;
  color: string;
  velocityX: number;
  velocityY: number;
  angle: number;
  visible: boolean;

  constructor(kind: EntityKind, x: number, y: number, radius: number, color: string) {
    this.kind = kind;
    this.x = x;
    this.y = y;
    this.radius = radius;
    this.width = radius * 2;
    this.height = radius * 2;
    this.color = color;
    this.velocityX = 0;
    this.velocityY = 0;
    this.angle = 0;
    this.visible = true;
  }

  update(gameWidth: number, gameHeight: number): void {
    this.x += this.velocityX;
    this.y += this.velocityY;

    if (this.x < -this.radius) this.x = gameWidth + this.radius;
    if (this.x > gameWidth + this.radius) this.x = -this.radius;
    if (this.y < -this.radius) this.y = gameHeight + this.radius;
    if (this.y > gameHeight + this.radius) this.y = -this.radius;
  }

  draw(ctx: CanvasRenderingContext2D): void {
    if (!this.visible) return;

    ctx.save();
    ctx.translate(this.x, this.y);
    ctx.rotate((this.angle * Math.PI) / 180);

    if (this.kind === 'sun') {
      ctx.beginPath();
      ctx.fillStyle = this.color;
      ctx.arc(0, 0, this.radius, 0, Math.PI * 2);
      ctx.fill();
    } else if (this.kind === 'bullet') {
      ctx.fillStyle = this.color;
      ctx.fillRect(-this.radius * 0.5, -this.radius * 0.5, this.radius, this.radius);
    } else {
      ctx.fillStyle = this.color;
      ctx.beginPath();
      ctx.moveTo(0, -this.radius);
      ctx.lineTo(this.radius * 0.8, this.radius * 0.8);
      ctx.lineTo(0, this.radius * 0.3);
      ctx.lineTo(-this.radius * 0.8, this.radius * 0.8);
      ctx.closePath();
      ctx.fill();
    }

    ctx.restore();
  }
}

export class Ship extends Sprite {
  health: number;
  score: number;
  availableBullets: number;
  firedBullets: number;
  exploded: boolean;

  constructor(x: number, y: number, color: string) {
    super('ship', x, y, 18, color);
    this.health = 1;
    this.score = 0;
    this.availableBullets = 10;
    this.firedBullets = 0;
    this.exploded = false;
  }

  accelerate(): void {
    const rad = (this.angle * Math.PI) / 180;
    this.velocityX += Math.cos(rad) * 0.18;
    this.velocityY += Math.sin(rad) * 0.18;
  }

  rotateRight(): void {
    this.angle += 3.5;
  }

  rotateLeft(): void {
    this.angle -= 3.5;
  }

  fire(): void {
    if (this.firedBullets >= this.availableBullets) return;
    this.firedBullets += 1;
  }

  damage(amount: number): boolean {
    this.health -= amount;
    return this.health <= 0;
  }

  reset(x: number, y: number, angle: number, velocityX: number, velocityY: number): void {
    this.x = x;
    this.y = y;
    this.angle = angle;
    this.velocityX = velocityX;
    this.velocityY = velocityY;
    this.health = 1;
    this.firedBullets = 0;
    this.exploded = false;
    this.visible = true;
  }
}

export class Bullet extends Sprite {
  life: number;

  constructor(x: number, y: number, color: string) {
    super('bullet', x, y, 5, color);
    this.life = 1.5;
  }

  applyGravity(sun: Sprite, gravityStrength: number): void {
    const dx = this.x - sun.x;
    const dy = this.y - sun.y;
    const dist = clamp(distance({ x: this.x, y: this.y }, { x: sun.x, y: sun.y }), 1, Infinity);
    const nx = dx / dist;
    const ny = dy / dist;

    const force = gravityStrength / (dist * dist);
    this.velocityX -= nx * force;
    this.velocityY -= ny * force;
  }
}

export function collides(a: Sprite, b: Sprite): boolean {
  return distance({ x: a.x, y: a.y }, { x: b.x, y: b.y }) < a.radius + b.radius;
}
