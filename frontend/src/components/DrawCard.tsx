// Import React and necessary hooks from 'react'
import React, { useState, useEffect } from 'react';
// Import useSelector and useDispatch from 'react-redux' for accessing and dispatching state
import { useSelector, useDispatch } from 'react-redux';
// Import Material UI components for UI design
import { Box, Button, Card, CardContent, Typography, CardMedia, Select, MenuItem, Grid, TextField, List, ListItem, ListItemText } from '@mui/material';
// Import actions from your userSlice for updating the Redux store
import { setRemainingDraws, setCollection } from '../store/userSlice';
// Import the RootState type from your store for TypeScript typing of state
import { RootState } from '../store/store';

// Define the DrawCard component
export const DrawCard = () => {
  const dispatch = useDispatch();
  // Use useSelector to access necessary pieces of the Redux state
  const pools = useSelector((state: RootState) => state.pool);
  const remainingDraws = useSelector((state: RootState) => state.user.remainingDraws);
  const userCollection = useSelector((state: RootState) => state.user.collection);
  const cardImageMap = useSelector((state: RootState) => state.cardImageMap);

  // Define component state
  const [selectedPool, setSelectedPool] = useState('');
  const [buyAmount, setBuyAmount] = useState('');
  const [drawnCard, setDrawnCard] = useState(0);
  const [displayingCard, setDisplayingCard] = useState<number | null>(null); // State for the simulated draw process

  // Function to handle the drawing of a card with probability
  const drawCardWithProbability = (poolName: string) => {
    const pool = pools[poolName];
    if (!pool) return null;

    let totalProb = 0;
    const rand = Math.random();
    for (let card of pool) {
      totalProb += card.prob;
      if (rand <= totalProb) {
        simulateDrawingProcess(card.id, pool); // Simulate the drawing process
        return card.id;
      }
    }
    return null;
  };

  // Function to simulate the draw process
  const simulateDrawingProcess = (finalCardId: number, pool: any[]) => {
    let count = 0;
    const maxIterations = 10; // Define the total number of iterations for the simulation
    const intervalId = setInterval(() => {
      const randomCardIndex = Math.floor(Math.random() * pool.length);
      setDisplayingCard(pool[randomCardIndex].id);
      count++;
      if (count >= maxIterations) {
        clearInterval(intervalId);
        setDrawnCard(finalCardId); // Set the final drawn card
      }
    }, 100); // Change the card every 100ms
  };

  // Function to handle the "Draw" button click
  const handleDrawClick = () => {
    if (remainingDraws > 0) {
      const drawnCardId = drawCardWithProbability(selectedPool);
      if (drawnCardId) {
        const existingCardIndex = userCollection.findIndex(card => card.id === drawnCardId);
        if (existingCardIndex >= 0) {
          const newCollection = userCollection.map((card, index) => {
            if (index === existingCardIndex) {
              return { ...card, quantity: card.quantity + 1 };
            }
            return card;
          });
          dispatch(setCollection(newCollection));
        } else {
          const newCard = { id: drawnCardId, quantity: 1 };
          dispatch(setCollection([...userCollection, newCard]));
        }
        dispatch(setRemainingDraws(remainingDraws - 1));
      }
    } else {
      alert('No remaining draws. Please purchase more.');
    }
  };

  // Function to handle the purchase of additional draws
  const handleBuyDraws = () => {
    const amount = parseInt(buyAmount, 10) || 0;
    dispatch(setRemainingDraws(remainingDraws + amount));
    setBuyAmount(''); // Reset the input field
  };

  return (
    <Box sx={{ flexGrow: 1 }}>
      <Typography variant="h4" gutterBottom>
        Draw a Card
      </Typography>
      <Grid container spacing={2}>
        <Grid item xs={8}>
          <Select
            value={selectedPool}
            onChange={(e) => setSelectedPool(e.target.value)}
            displayEmpty
            fullWidth
          >
            {Object.keys(pools).map((poolName) => (
              <MenuItem key={poolName} value={poolName}>
                {poolName}
              </MenuItem>
            ))}
          </Select>
          {/* Display card probabilities */}
          {selectedPool && (
            <List sx={{ mt: 2 }} dense>
              {pools[selectedPool].map((card) => (
                <ListItem key={card.id}>
                  <ListItemText primary={`Card ID: ${card.id} - Probability: ${card.prob}`} />
                </ListItem>
              ))}
            </List>
          )}
          <Card raised sx={{ mt: 2 }}>
            <CardContent>
              <Button variant="contained" onClick={handleDrawClick} disabled={!selectedPool || remainingDraws <= 0}>
                Draw
              </Button>
            </CardContent>
            {displayingCard && (
              <CardMedia
                component="img"
                image={cardImageMap[displayingCard] || ''}
                alt={`Card ${displayingCard}`}
                sx={{ p: 2 }}
              />
            )}
          </Card>
        </Grid>
        <Grid item xs={4}>
          <Card raised sx={{ maxWidth: 345, height: '100%' }}>
            <CardContent>
              <Typography gutterBottom variant="h5">
                Remaining Draws: {remainingDraws}
              </Typography>
              <Typography gutterBottom variant="h5">
                Quick Add Draws
              </Typography>
              <TextField
                fullWidth
                type="number"
                value={buyAmount}
                onChange={(e) => setBuyAmount(e.target.value)}
                placeholder="Amount to Buy"
                variant="outlined"
                sx={{ mb: 2 }}
              />
              <Button variant="contained" fullWidth onClick={handleBuyDraws}>
                Buy Draws
              </Button>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
};

// Default export of DrawCard component
export default DrawCard;
