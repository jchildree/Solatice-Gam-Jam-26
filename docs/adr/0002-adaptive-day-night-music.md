# Adaptive day/night background music

AudioManager plays two BGM tracks and swaps them on each Toggle: one warm track for Day, one darker track for Night. We chose this over a single looped track because the day/night toggle is the core mechanic -- the music shifting on toggle reinforces the state change and makes the world feel alive. The extra cost is two audio files and swap logic in AudioManager.

## Considered options

- **Adaptive (chosen):** two tracks, swap on Toggle. Music mirrors world state.
- **Single track:** one looped BGM for entire game. Zero extra code, but misses the mechanic reinforcement.
