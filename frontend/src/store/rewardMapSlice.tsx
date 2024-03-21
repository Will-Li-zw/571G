// src/store/rewardMapSlice.ts
import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { RewardMap } from '../types';

const initialState: RewardMap = {
  'Reward1': [
    { id: 1, quantity: 1 },
    { id: 2, quantity: 1 },
  ],
  // Add more rewards as needed
};

export const rewardMapSlice = createSlice({
  name: 'rewardMap',
  initialState,
  reducers: {
    setRewardMap: (state, action: PayloadAction<RewardMap>) => {
      return action.payload;
    },
    addOrUpdateReward: (state, action: PayloadAction<{ rewardName: string; rewards: { id: number; quantity: number }[] }>) => {
      const { rewardName, rewards } = action.payload;
      state[rewardName] = rewards;
    },
    
  },
});

export const { setRewardMap, addOrUpdateReward } = rewardMapSlice.actions;
export default rewardMapSlice.reducer;
