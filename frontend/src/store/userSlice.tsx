// src/store/userSlice.ts
import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { UserState ,Card} from '../types';

// Initial state
const initialState: UserState = {
  remainingDraws: 0,
  collection: [],
};

export const userSlice = createSlice({
  name: 'user',
  initialState,
  reducers: {
    setRemainingDraws: (state, action: PayloadAction<number>) => {
      state.remainingDraws = action.payload;
    },
    setCollection: (state, action: PayloadAction<Card[]>) => {
      state.collection = action.payload;
    },
  },
});

// Actions
export const { setRemainingDraws, setCollection } = userSlice.actions;

export default userSlice.reducer;
