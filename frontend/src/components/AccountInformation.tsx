import React, { useState, useEffect } from 'react';
import { Typography, Card, CardContent, CardMedia, Grid, CircularProgress } from '@mui/material';

// Assume you have a function to get random images. For demo purposes, let's use placeholder images.
const getDrawTimes = async () => {
  // Mock balance fetching logic
  await new Promise((resolve) => setTimeout(resolve, 100));
  return 10;
};

const getCollection = async () => {
  // Mock collection fetching logic
  await new Promise((resolve) => setTimeout(resolve, 100));
  return [
    { id: 1, name: 'Card 1' },
    { id: 2, name: 'Card 2' },
    { id: 3, name: 'Card 3' },
    { id: 3, name: 'Card 3' },
    { id: 3, name: 'Card 3' },
    { id: 3, name: 'Card 3' },
    { id: 3, name: 'Card 3' },

  ];
};

const getRandomImage = (cardId:number) => {
  // Here, you'd fetch or calculate an image URL based on the cardId or some other logic.
  // For demonstration, return a placeholder or any image URL.
  const images = [
    'https://i.postimg.cc/3RXLFz5z/163111-1710059471b82d.jpg',
    'https://i.postimg.cc/fR41mGPj/194048-1710070848523b.jpg',
    'https://i.postimg.cc/rFTPp1RQ/TEC3-L07-N0965-lead-720x1280.png',
    // Add more as needed or fetch dynamically
  ];
  return images[cardId % images.length]; // Simple modulus to cycle through images
};

const useAccountData = () => {
  const [drawTimes, setDrawTimes] = useState<number | null>(null);
  const [collection, setCollection] = useState<{ id: number; name: string }[] | null>(null);

  useEffect(() => {
    const fetchData = async () => {
      setDrawTimes(await getDrawTimes());
      setCollection(await getCollection());
    };
    fetchData();
  }, []);

  return { drawTimes, collection };
};

const AccountInformation = () => {
  const { drawTimes, collection } = useAccountData();

  return (
    <Grid container spacing={2} padding={2} alignItems="flex-start">
      <Grid item xs={12}>
        <Typography variant="h5" gutterBottom>
          Draw Times Remaining
        </Typography>
        {drawTimes !== null ? (
          <Typography variant="body1">{drawTimes}</Typography>
        ) : (
          <CircularProgress />
        )}
      </Grid>
      <Grid item xs={12}>
        <Typography variant="h5" gutterBottom>
          My Collection
        </Typography>
        <Grid container spacing={2}>
          {collection !== null ? (
            collection.map((card, index) => (
              <Grid item xs={12} sm={6} md={3} key={index}>
                <Card>
                  <CardMedia
                    component="img"
                    height="140"
                    image={getRandomImage(card.id)}
                    alt={card.name}
                  />
                  <CardContent>
                    <Typography variant="body1" textAlign="center">
                      {card.name}
                    </Typography>
                  </CardContent>
                </Card>
              </Grid>
            ))
          ) : (
            <CircularProgress />
          )}
        </Grid>
      </Grid>
    </Grid>
  );
};

export default AccountInformation;
