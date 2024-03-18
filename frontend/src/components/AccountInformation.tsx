// AccountInformation.tsx
import React from 'react';
import { useSelector } from 'react-redux';
import { Typography, Card, CardContent, CardMedia, Grid, CircularProgress } from '@mui/material';
import { RootState } from '../store/store';

const AccountInformation = () => {
  const { remainingDraws, collection } = useSelector((state: RootState) => state.user);
  const cardImageMap = useSelector((state: RootState) => state.cardImageMap);
  console.log(remainingDraws)
  if (remainingDraws === null || collection === null) {
    return <CircularProgress />;
  }

  return (
    <Grid container spacing={2} padding={2} alignItems="flex-start">
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
          {collection.map((card) => (
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
