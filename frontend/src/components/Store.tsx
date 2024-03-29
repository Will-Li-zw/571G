import React from 'react';
import { useSelector, useDispatch } from 'react-redux';
import { useState } from 'react';
// import { Grid, Card as MuiCard, CardContent, Button, Typography, CardMedia } from '@mui/material';
import { Grid, Card, CardActionArea, CardActions, CardContent, Button, Typography, CardMedia, Box,Backdrop,CircularProgress } from '@mui/material';
import { setCollection } from '../store/userSlice'; // Adjust the import path as necessary
import { RootState } from '../store/store';
import { redeemAward } from '../store/interact';
import Web3 from 'web3';

export interface RewardMap {
  [rewardName: string]: { id: number; quantity: number }[];
}

export const Store = () => {
  const dispatch = useDispatch();
  const web3 = new Web3("https://eth-sepolia.g.alchemy.com/v2/z850kJyohcSo3z59MLbQS65ASRz9NavH");;
  const [isLoading, setIsLoading] = useState(false);
  const userCollection = useSelector((state: RootState) => state.user.collection);
  const storeContent: RewardMap = useSelector((state: RootState) => state.reward);
  const cardImage = useSelector((state: RootState) => state.cardImageMap);

  const redeemClick = async (rewardName: string) => {
    const awards = storeContent[rewardName];
    if (!awards) return;

    const canRedeem = awards.every(award => {
      const userCard = userCollection.find(c => c.id === award.id);
      return userCard && userCard.quantity >= award.quantity;
    });

    if (canRedeem) {
      // Simulate an API call
      try {
        const waitForTransactionReceipt = async (hash: any) => {
          setIsLoading(true)
          let receipt = null;
          while (receipt === null) { // Polling for receipt
            try {
              receipt = await web3.eth.getTransactionReceipt(hash);
              // Wait for a short period before polling again to avoid rate limits
              await new Promise(resolve => setTimeout(resolve, 2000));
              setIsLoading(false)

            } catch (error) {
              await new Promise(resolve => setTimeout(resolve, 2000));
              console.error('Error fetching transaction receipt: ', error);
            }
          }
          return receipt;
        };
        console.log("Page redeem", rewardName)
        const hex = await redeemAward(rewardName); // Mock API call delay
        await waitForTransactionReceipt(hex);
        const updatedCollection = userCollection.map(userCard => {
          const awardToRedeem = awards.find(a => a.id === userCard.id);
          if (awardToRedeem) {
            return { ...userCard, quantity: userCard.quantity - awardToRedeem.quantity };
          }
          return userCard;
        });
  
        dispatch(setCollection(updatedCollection));
        alert('Award redeemed successfully!');
      } catch (error) {
        alert('Award redeemed failed'+error);
        
      }

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
      <Backdrop open={isLoading}>
      <CircularProgress color="inherit" />
      </Backdrop>
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
                <Button variant="contained" color="primary" onClick={() => redeemClick(rewardName)}>
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
