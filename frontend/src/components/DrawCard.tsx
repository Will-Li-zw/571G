import React, { useState, useEffect } from 'react';
import { Box, Button, Card, CardContent, Grid, TextField, Typography, Select, MenuItem } from '@mui/material';

// Images array
const images = [
  'https://i.postimg.cc/3RXLFz5z/163111-1710059471b82d.jpg',
  'https://i.postimg.cc/fR41mGPj/194048-1710070848523b.jpg',
  'https://i.postimg.cc/rFTPp1RQ/TEC3-L07-N0965-lead-720x1280.png',
  // Add more as needed
];

// Mockup function to get a random image
const getRandomImage = () => {
  const cardId = Math.floor(Math.random() * images.length);
  return images[cardId];
};

// Mockup function to simulate drawing a card with probabilities
const drawCardWithProbability = () => {
  const probabilities = [
    { cardId: 0, chance: 0.5 }, // 50% chance for the first image
    { cardId: 1, chance: 0.3 }, // 30% chance for the second image
    { cardId: 2, chance: 0.2 }, // 20% chance for the third image
    // Add more as needed
  ];

  const random = Math.random();
  let sum = 0;

  for (let i = 0; i < probabilities.length; i++) {
    sum += probabilities[i].chance;
    if (random <= sum) {
      return probabilities[i].cardId;
    }
  }

  return 0; // Default to the first card if something goes wrong
};

export const DrawCard = () => {
  const [selectedImage, setSelectedImage] = useState(images[0]); // Start with the first image
  const [isDrawing, setIsDrawing] = useState(false);
  const [drawTimes, setDrawTimes] = useState(5); // Initial draw times
  const [buyAmount, setBuyAmount] = useState('');
  const [selectedWheel, setSelectedWheel] = useState('wheel1');

  useEffect(() => {
    let interval: NodeJS.Timeout;
    if (isDrawing) {
      interval = setInterval(() => {
        setSelectedImage(getRandomImage()); // Change images rapidly
      }, 100); // Change image every 100 milliseconds
    }

    setTimeout(() => {
      if (isDrawing) {
        clearInterval(interval);
        const drawnCardId = drawCardWithProbability();
        setSelectedImage(images[drawnCardId]);
        setIsDrawing(false);
      }
    }, 2000); // Simulate the drawing process for 2 seconds

    return () => clearInterval(interval);
  }, [isDrawing]);

  const handleDrawClick = () => {
    setIsDrawing(true);
    setDrawTimes((prev) => prev - 1); // Decrease draw times by 1 after each draw
  };

  const handleBuyDraws = () => {
    // Assuming the purchase is always successful
    setDrawTimes((prev) => prev + parseInt(buyAmount));
  };

  return (
    <Grid container spacing={2} padding={2}>
      <Grid item xs={12} md={8}>
        <Typography variant="h6">Draw a Card</Typography>
        <Select
          value={selectedWheel}
          onChange={(e) => setSelectedWheel(e.target.value)}
          fullWidth
          displayEmpty
          inputProps={{ 'aria-label': 'Without label' }}
        >
          <MenuItem value="wheel1">Wheel 1</MenuItem>
          <MenuItem value="wheel2">Wheel 2</MenuItem>
          {/* Add more wheels as needed */}
        </Select>
        <img src={selectedImage} alt="Drawn Card" style={{ marginTop: '20px' }} />
        <Box mt={2} display="flex" justifyContent="center" alignItems="center">
          <Button variant="contained" onClick={handleDrawClick} disabled={isDrawing || drawTimes <= 0}>
            {isDrawing ? 'Drawing...' : 'Draw a Card'}
          </Button>
        </Box>
      </Grid>
      <Grid item xs={12} md={4}>
        <Typography variant="h6">Quick Buy</Typography>
        <Typography>Draw Times Remaining: {drawTimes}</Typography>
        <TextField
          fullWidth
          type="number"
          label="Amount of Draws"
          value={buyAmount}
          onChange={(e) => setBuyAmount(e.target.value)}
          margin="normal"
        />
        <Typography>Price: {10 * parseInt(buyAmount || '0')}</Typography>
        <Button variant="contained" onClick={handleBuyDraws} sx={{ mt: 1 }} disabled={isDrawing}>
          Buy Draws
        </Button>
      </Grid>
    </Grid>
  );
};
