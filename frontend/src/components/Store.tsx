import React from 'react';
import { useSelector, useDispatch } from 'react-redux';
// import { Grid, Card as MuiCard, CardContent, Button, Typography, CardMedia } from '@mui/material';
import { Grid, Card, CardActionArea, CardActions, CardContent, Button, Typography, CardMedia, Box } from '@mui/material';
import { setCollection } from '../store/userSlice'; // Adjust the import path as necessary
import { RootState } from '../store/store';

export interface RewardMap {
  [rewardName: string]: { id: number; quantity: number }[];
}

export const Store = () => {
  const dispatch = useDispatch();
  const userCollection = useSelector((state: RootState) => state.user.collection);
  const storeContent: RewardMap = useSelector((state: RootState) => state.reward);
  const cardImage = useSelector((state: RootState) => state.cardImageMap);

  const redeemAward = async (rewardName: string) => {
    const awards = storeContent[rewardName];
    if (!awards) return;

    const canRedeem = awards.every(award => {
      const userCard = userCollection.find(c => c.id === award.id);
      return userCard && userCard.quantity >= award.quantity;
    });

    if (canRedeem) {
      // Simulate an API call
      await new Promise(resolve => setTimeout(resolve, 1000)); // Mock API call delay

      const updatedCollection = userCollection.map(userCard => {
        const awardToRedeem = awards.find(a => a.id === userCard.id);
        if (awardToRedeem) {
          return { ...userCard, quantity: userCard.quantity - awardToRedeem.quantity };
        }
        return userCard;
      });

      dispatch(setCollection(updatedCollection));
      alert('Award redeemed successfully!');
    } else {
      alert('Insufficient cards to redeem this award.');
    }
  };

  // Function to get image URL by card ID (you'll need to implement this based on your own logic)
  const getImageUrlForCardId = (cardId: number): string => {
    // Replace with your actual image retrieval logic

    return cardImage[cardId];
  };

  return (
    <Grid container spacing={2} sx={{ padding: 2 }}>
      {Object.entries(storeContent).map(([rewardName, rewards]) => (
        <Grid item xs={12} sm={6} lg={4} key={rewardName}>
          <Card raised sx={{ maxWidth: 345, mb: 2 }}>
            <CardContent>
              <Typography gutterBottom variant="h5" component="div">
                {rewardName}
              </Typography>
            </CardContent>
            {rewards.map((reward) => (
              <CardActionArea key={reward.id}>
                <CardMedia
                  component="img"
                  image={getImageUrlForCardId(reward.id)}
                  alt={`Card ${reward.id}`}
                  sx={{ height: 140, objectFit: 'contain' }} // Adjust as necessary
                />
                <CardContent>
                  <Typography variant="body2" color="text.secondary">
                    Quantity: {reward.quantity}
                  </Typography>
                </CardContent>
              </CardActionArea>
            ))}
            <CardActions>
              <Box sx={{ display: 'flex', justifyContent: 'center', width: '100%' }}>
                <Button variant="contained" color="primary" onClick={() => redeemAward(rewardName)}>
                  Redeem
                </Button>
              </Box>
            </CardActions>
          </Card>
        </Grid>
      ))}
    </Grid>
  );
  
};

export default Store;
