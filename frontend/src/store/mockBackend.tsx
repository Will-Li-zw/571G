// src/store/mockBackend.ts
import { Card, CardImageMap, RewardMap, PoolProbMap} from '../types';
export const fetchUserData = async (): Promise<{ remainingDraws: number; collection: Card[] }> => {
  await new Promise((resolve) => setTimeout(resolve, 1000)); // Simulated network delay

  // Simulated response data
  return {
    remainingDraws: 5,
    collection: [
      { id: 1, quantity: 30 },
      { id: 2, quantity: 22 },
      { id: 3, quantity: 11 },
    ],
  };
};

// AddressToBalance: Address => number
// AddressToCollection: Address => [[Id, Amount]]
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
export const fetchPoolData = async (): Promise<PoolProbMap> => {
    await new Promise((resolve) => setTimeout(resolve, 500));
    return {
      'Pool1': [
        { id: 1, prob: 0.5 },
        { id: 2, prob: 0.3 },
        { id: 3, prob: 0.2 },
      ],
      'Pool2': [
        { id: 1, prob: 0.5 },
        { id: 3, prob: 0.5 },
      ],
      // ... other pool data
    };
  };
  
  export const fetchRewardData = async (): Promise<RewardMap> => {
    await new Promise((resolve) => setTimeout(resolve, 500));
    return {
      'Reward1': [
        { id: 1, quantity: 1 },
        { id: 2, quantity: 1 },
      ],
      'Reward2': [
        { id: 3, quantity: 1 },
      ],
      'Reward3': [
        { id: 3, quantity: 10 },
        { id: 1, quantity: 10 },
        { id: 2, quantity: 10 },

      ],
      // ... other reward data
    };
  };