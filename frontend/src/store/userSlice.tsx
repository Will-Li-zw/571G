// src/store/userSlice.ts
import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { UserState ,Card} from '../types';

// Initial state
const initialState: UserState = {
  address:"",
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
    setAddress: (state, action: PayloadAction<string>) => {
      state.address = action.payload;
    },
  },
})
  
  // Remember to export the new action
export const { setRemainingDraws, setCollection, setAddress } = userSlice.actions;

export default userSlice.reducer;
