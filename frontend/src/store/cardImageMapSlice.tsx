// src/store/cardImageMapSlice.ts
import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { CardImageMap } from '../types';

const initialState: CardImageMap = {};

export const cardImageMapSlice = createSlice({
  name: 'cardImageMap',
  initialState,
  reducers: {
    setCardImageMap: (state, action: PayloadAction<CardImageMap>) => {
      return action.payload;
    },
  },
});

export const { setCardImageMap } = cardImageMapSlice.actions;
export default cardImageMapSlice.reducer;
