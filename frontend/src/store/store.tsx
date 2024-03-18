// src/store/store.ts
import { configureStore } from '@reduxjs/toolkit';
import userReducer from './userSlice';
import cardImageMapReducer from './cardImageMapSlice';

export const store = configureStore({
  reducer: {
    user: userReducer,
    cardImageMap: cardImageMapReducer,
  },
});

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;
