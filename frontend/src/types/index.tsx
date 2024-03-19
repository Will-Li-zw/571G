// src/types/index.ts
export interface Card {
  id: number;
  quantity: number;
}

export interface UserState {
  remainingDraws: number;
  collection: Card[];
}

export interface CardImageMap {
  [id: number]: string;
}

export interface PoolProbMap {
  [poolName: string]: { id: number; prob: number }[];
}

export interface RewardMap {
  [rewardName: string]: { id: number; quantity: number }[];
}
