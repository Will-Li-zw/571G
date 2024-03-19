// src/store/store.ts
import { configureStore } from '@reduxjs/toolkit';
import userReducer from './userSlice';
import cardImageMapReducer from './cardImageMapSlice';
import poolReducer from './poolProbMapSlice'
import rewardReducer from './rewardMapSlice'

export const store = configureStore({
    reducer: {
      user: userReducer,
      cardImageMap: cardImageMapReducer,
      pool: poolReducer,
      reward: rewardReducer,
    },
  });

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;
