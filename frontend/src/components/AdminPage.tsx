// Adjust paths as necessary
import React, { useState } from 'react';
import { useDispatch ,useSelector} from 'react-redux';
import { Box, Button, TextField, Typography } from '@mui/material';
import { setRewardMap } from '../store/rewardMapSlice';
import { setPoolProbMap } from '../store/poolProbMapSlice';
import { setCardImageMap } from '../store/cardImageMapSlice';
import { RootState } from '../store/store';
import { RewardMap ,Card} from '../types';
import { adminCreate } from '../store/interact';

export const AdminPage = () => {
  const cardImageMap = useSelector((state: RootState) => state.cardImageMap);
  const storeContent: RewardMap = useSelector((state: RootState) => state.reward);

  const dispatch = useDispatch();
  const [collectorName, setCollectorName] = useState('');
  const [cards, setCards] = useState([{ url: '', prob: '' }]);
  const [awardName, setAwardName] = useState('');
  const pools = useSelector((state: RootState) => state.pool);


  const handleCardChange = (index: number, field: any, value: any) => {
    const newCards = [...cards];
    newCards[index] = { ...newCards[index], [field]: value };
    setCards(newCards);
  };

  const addCard = () => {
    setCards([...cards, { url: '', prob: '' }]);
  };

  const validateProbabilities = () => {
    const sum = cards.reduce((acc, card) => acc + parseFloat(card.prob), 0);
    return sum.toFixed(2) === '1.00';
  };

  const handleSubmit = async () => {
    if (!validateProbabilities()) {
      alert('The sum of probabilities must be 1. Please adjust the card probabilities.');
      return;
    }

    // Simulate sending data to a backend
    console.log(`Collector Name: ${collectorName}, Cards: ${JSON.stringify(cards)}, Award Name: ${awardName}`);
    const startingId = Object.keys(cardImageMap).reduce((maxId, currentId) => Math.max(maxId, parseInt(currentId, 10)), 0) + 1;

    try {
      await adminCreate(collectorName, awardName, cards.map(card => parseInt(card.prob)*100), cards.map(card => card.url));
      // // Assuming each card quantity is 1 for simplicity
      // const awardCards = cards.map((card, index) => ({ id: index + 100, quantity: 1 })); // Example ID logic
      // await setCollectionAward(awardName, awardCards);
      const cardIds = cards.map((_, index) => index + 100); // Mock IDs as incremental numbers
      
      // Dispatch updates to Redux
      dispatch(setRewardMap({...storeContent, [awardName]: cardIds.map(id => ({ id, quantity: 1 })) }));
      dispatch(setPoolProbMap({ ...pools, [collectorName]: cards.map((card, index) => ({ id: cardIds[index], prob: parseFloat(card.prob) })) }));
      dispatch(setCardImageMap({
        ...cardImageMap,
        ...cards.reduce((acc, card, index) => ({
          ...acc,
          [cardIds[index]]: card.url
        }), {})
      }));
      alert('Submission successful!');

  } catch (error:any) {
      alert(`Submission failed: ${error.message}`);
  }
    const cardIds = cards.map((_, index) => index + 100); // Mock IDs as incremental numbers


  };

  return (
  <Box sx={{ '& > :not(style)': { m: 1 }, marginTop: 5 }}>
    <Typography variant="h4" gutterBottom>
      Admin Page
    </Typography>
    <TextField
      label="Collector Name"
      value={collectorName}
      onChange={(e) => setCollectorName(e.target.value)}
      fullWidth
      margin="normal"
    />
    {cards.map((card, index) => (
      <Box key={index} sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
        <TextField
          label={`Card ${index + 1} URL`}
          value={card.url}
          onChange={(e) => handleCardChange(index, 'url', e.target.value)}
          fullWidth
        />
        <TextField
          label="Probability"
          type="number"
          value={card.prob}
          onChange={(e) => handleCardChange(index, 'prob', e.target.value)}
          inputProps={{ step: 0.01, min: 0, max: 1 }}
        />
      </Box>
    ))}
    <Button onClick={addCard} variant="contained">Add Card</Button>
    <TextField
      label="Award Name"
      value={awardName}
      onChange={(e) => setAwardName(e.target.value)}
      fullWidth
      margin="normal"
    />
    <Button onClick={handleSubmit} variant="contained" color="primary" sx={{ mt: 2 }}>
      Submit
    </Button>
  </Box>
);
};

export default AdminPage;
