export type InputState = {
  accelerate: boolean;
  rotateRight: boolean;
  rotateLeft: boolean;
  fire: boolean;
};

export class InputManager {
  private readonly keyState = new Set<string>();
  private readonly players: InputState[];

  constructor() {
    this.players = [
      { accelerate: false, rotateRight: false, rotateLeft: false, fire: false },
      { accelerate: false, rotateRight: false, rotateLeft: false, fire: false },
    ];

    window.addEventListener('keydown', (event) => {
      if (['Space', 'ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight'].includes(event.code)) {
        event.preventDefault();
      }
      this.keyState.add(event.code);
      this.updateFromKeyState();
    });

    window.addEventListener('keyup', (event) => {
      this.keyState.delete(event.code);
      this.updateFromKeyState();
    });
  }

  getPlayerState(playerIndex: number): InputState {
    return this.players[playerIndex];
  }

  private updateFromKeyState(): void {
    this.players[0] = {
      accelerate: this.keyState.has('KeyW'),
      rotateRight: this.keyState.has('KeyD'),
      rotateLeft: this.keyState.has('KeyA'),
      fire: this.keyState.has('KeyS'),
    };

    this.players[1] = {
      accelerate: this.keyState.has('ArrowUp'),
      rotateRight: this.keyState.has('ArrowRight'),
      rotateLeft: this.keyState.has('ArrowLeft'),
      fire: this.keyState.has('ArrowDown'),
    };
  }
}
