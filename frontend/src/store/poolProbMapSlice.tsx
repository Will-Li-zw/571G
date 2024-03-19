// src/store/poolProbMapSlice.ts
import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { PoolProbMap } from '../types';

const initialState: PoolProbMap = {};

export const poolProbMapSlice = createSlice({
  name: 'poolProbMap',
  initialState,
  reducers: {
    setPoolProbMap: (state, action: PayloadAction<PoolProbMap>) => {
      return action.payload;
    },
  },
});

export const { setPoolProbMap } = poolProbMapSlice.actions;
export default poolProbMapSlice.reducer;
