// AccountInformation.tsx
import React from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { Typography, Card, CardContent, CardMedia, Grid, CircularProgress, Button, Backdrop } from '@mui/material';
import { RootState } from '../store/store';
import { redeemChance } from '../store/interact';
import { setCollection, setRemainingDraws } from '../store/userSlice';
import { Web3 } from 'web3';
import { useState } from 'react';
const AccountInformation = () => {
  const { remainingDraws, collection } = useSelector((state: RootState) => state.user);
  const cardImageMap = useSelector((state: RootState) => state.cardImageMap);
  const account = useSelector((state: RootState) => state.user.address);
  const dispatch = useDispatch();
  const userCollection = useSelector((state: RootState) => state.user.collection);
  const web3 = new Web3("https://eth-sepolia.g.alchemy.com/v2/z850kJyohcSo3z59MLbQS65ASRz9NavH");
  const [isLoading, setIsLoading] = useState(false);

  const handleCardButtonClick = async(cardId: number) => {
    // This function will be called when the button under a card is clicked.
    // You can replace the alert with any other functionality you need.
    try {
      const waitForTransactionReceipt = async (hash: any) => {
        let receipt = null;
        setIsLoading(true)
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
      const hex = await redeemChance(cardId)
      await waitForTransactionReceipt(hex);
      dispatch(setRemainingDraws(remainingDraws + 1));

      const newCollection = userCollection.map((card, index) => {
        if (card.id === cardId) {
          return { ...card, quantity: card.quantity - 4 };
        }
        return card;
      });
      console.log(newCollection)
      dispatch(setCollection(newCollection));
      alert("Redeem"+ cardId+ "Successfully")
      console.log("Redeem"+ cardId+ "Successfully")
    } catch (error) {
      setIsLoading(false)

      alert("Redeem Failed")
    }
  };

  if (account === null || collection === null) {
    return <CircularProgress />;
  }

  return (
    <Grid container spacing={2} padding={2} alignItems="flex-start">
      <Backdrop open={isLoading}>
      <CircularProgress color="inherit" />
      </Backdrop>
      <Grid item xs={12}>
        <Typography variant="h5" gutterBottom>
          Draw Times Remaining: {remainingDraws}
        </Typography>
      </Grid>
      <Grid item xs={12}>
        <Typography variant="h5" gutterBottom>
          My Collection
        </Typography>
        <Grid container spacing={2}>
        {collection.filter(card => card.quantity !== 0).map((card) => (
      <Grid item xs={12} sm={6} md={3} key={card.id}>
    <Card>
      <CardMedia
        component="img"
        height="140"
        image={cardImageMap[card.id] || 'https://via.placeholder.com/150'}
        alt={`Card ${card.id}`}
      />
      <CardContent>
        <Typography variant="body1" textAlign="center">
          {`Card ${card.id} (x${card.quantity})`}
        </Typography>
        <Button 
          variant="contained" 
          color="primary" 
          onClick={() => handleCardButtonClick(card.id)}
          style={{marginTop: '10px'}}
        >
          Redeem
        </Button>
      </CardContent>
    </Card>
  </Grid>
))}

        </Grid>
      </Grid>
    </Grid>
  );
};

export default AccountInformation;