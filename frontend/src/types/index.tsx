// src/types/index.ts
export interface Card {
  id: number;
  quantity: number; // Represents the number of this card that the user holds
}

export interface UserState {
  remainingDraws: number;
  collection: Card[];
}

// New type for mapping card IDs to image URLs
export interface CardImageMap {
  [id: number]: string;
}
