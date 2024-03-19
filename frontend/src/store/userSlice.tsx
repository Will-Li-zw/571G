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
    // New reducer to deduct a specific card quantity
    deductCardFromCollection: (state, action: PayloadAction<{id: number, quantity: number}>) => {
      const { id, quantity } = action.payload;
      const cardIndex = state.collection.findIndex(card => card.id === id);
      if (cardIndex !== -1) {
        // Deduct the quantity and remove the card if the quantity reaches 0
        state.collection[cardIndex].quantity -= quantity;
        if (state.collection[cardIndex].quantity <= 0) {
          state.collection.splice(cardIndex, 1);
        }
      }
    },
    // Add more reducers as needed
  },
})
  
  // Remember to export the new action
export const { setRemainingDraws, setCollection, deductCardFromCollection } = userSlice.actions;

export default userSlice.reducer;
