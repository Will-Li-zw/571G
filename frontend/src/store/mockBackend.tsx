// src/store/mockBackend.ts
import { Card, CardImageMap } from '../types';

export const fetchUserData = async (): Promise<{ remainingDraws: number; collection: Card[] }> => {
  await new Promise((resolve) => setTimeout(resolve, 1000)); // Simulated network delay

  // Simulated response data
  return {
    remainingDraws: 5,
    collection: [
      { id: 1, quantity: 3 },
      { id: 2, quantity: 2 },
      { id: 3, quantity: 1 },
    ],
  };
};

// AddressToBalance:
// AddressToCollection:
// PooltoIDmap: PoolName => [Ids]
// PooltoProbmap: PoolName => [Probs]
// ReedeemMap: RewardName => [Ids]




export const fetchCardImageMap = async (): Promise<CardImageMap> => {
  await new Promise((resolve) => setTimeout(resolve, 500)); // Simulated shorter network delay

  // Simulated image URL map
  return {
    1:'https://i.postimg.cc/3RXLFz5z/163111-1710059471b82d.jpg',
    2:'https://i.postimg.cc/fR41mGPj/194048-1710070848523b.jpg',
    3:'https://i.postimg.cc/rFTPp1RQ/TEC3-L07-N0965-lead-720x1280.png',
  };
};
